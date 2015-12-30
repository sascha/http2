defmodule HTTP2 do
  alias HTTP2.State
  alias HTTP2.Protocol

  @type headers :: [{binary, iodata}]

  @spec open(String.t, :inet.port_number, Keyword.t) :: {:ok, pid}
  def open(host, port, opts \\ []) do
    Task.Supervisor.start_child(HTTP2.Supervisor, __MODULE__, :init,
    [self(), String.to_char_list(host), port, opts])
  end

  @spec init(pid, char_list, :inet.port_number, Keyword.t) :: no_return
  def init(owner, host, port, opts) do
    retry = Dict.get(opts, :retry, 5)
    transport = case Dict.get(opts, :transport, default_transport(port)) do
      :tcp ->
        :ranch_tcp
      :ssl ->
        :ranch_ssl
    end

    connect(%State{
      owner: owner,
      host: host,
      port: port,
      opts: opts,
      transport: transport}, retry)
  end

  # HTTP Methods

  @spec head(pid, iodata, headers) :: reference
  def head(server_pid, path, headers \\ []) do
    request(server_pid, "HEAD", path, headers)
  end

  @spec get(pid, iodata, headers) :: reference
  def get(server_pid, path, headers \\ []) do
    request(server_pid, "GET", path, headers)
  end

  @spec options(pid, iodata, headers) :: reference
  def options(server_pid, path, headers \\ []) do
    request(server_pid, "OPTIONS", path, headers)
  end

  @spec delete(pid, iodata, headers) :: reference
  def delete(server_pid, path, headers \\ []) do
    request(server_pid, "DELETE", path, headers)
  end

  @spec post(pid, iodata, headers, iodata) :: reference
  def post(server_pid, path, headers \\ [], body \\ <<>>) do
    request(server_pid, "POST", path, headers, body)
  end

  @spec put(pid, iodata, headers, iodata) :: reference
  def put(server_pid, path, headers \\ [], body \\ <<>>) do
    request(server_pid, "PUT", path, headers, body)
  end

  @spec patch(pid, iodata, headers, iodata) :: reference
  def patch(server_pid, path, headers \\ [], body \\ <<>>) do
    request(server_pid, "PATCH", path, headers, body)
  end

  @spec request(pid, iodata, iodata, Keyword.t, iodata) :: reference
  def request(server_pid, method, path, headers \\ [], body \\ <<>>) do
    stream_ref = make_ref
    send(server_pid, {:request, self(), stream_ref, method, path, headers, body})
    stream_ref
  end

  # Private

  @spec default_transport(:inet.port_number) :: :ssl | :tcp
  defp default_transport(443) do
    :ssl
  end

  defp default_transport(_) do
    :tcp
  end

  @spec connect(State.t, non_neg_integer) :: no_return
  defp connect(%State{
    host: host,
    port: port,
    opts: opts,
    transport: transport = :ranch_ssl} = state, retries) do
      transport_opts = [
        :binary,
        {:active, false},
        {:alpn_advertised_protocols, ["h2"]}
        | Dict.get(opts, :transport_opts, [])
      ]

      case transport.connect(host, port, transport_opts) do
        {:ok, socket} ->
          case :ssl.negotiated_protocol(socket) do
            {:ok, _} ->
              IO.puts("connected via TLS")
              up(state, socket)
            _ ->
              exit(:protocol_not_supported)
          end
        {:error, _} ->
          retry(state, retries)
      end
  end

  defp connect(%State{
    host: host,
    port: port,
    opts: opts,
    transport: transport} = state, retries) do
      transport_opts = [
        :binary,
        {:active, false}
        | Dict.get(opts, :transport_opts, [])
      ]

      case transport.connect(host, port, transport_opts) do
        {:ok, socket} ->
          IO.puts("connected without TLS")
          up(state, socket)
        {:error, _} ->
          retry(state, retries)
      end
  end

  # Retry logic

  @spec retry(State.t, non_neg_integer) :: no_return
  defp retry(_, 0) do
    exit(:gone)
  end

  defp retry(%State{opts: opts} = state, retries) do
    Process.send_after(self(), :retry, Dict.get(opts, :retry_timeout, 5000))
    receive do
      :retry ->
        connect(state, retries - 1)
    end
  end

  # Up/down logic

  @spec up(State.t, :inet.socket | :ssl.sslsocket) :: no_return
  defp up(%State{owner: owner, transport: transport} = state, socket) do
    proto_state = Protocol.init(owner, socket, transport)
    proto_state = Protocol.preface(proto_state)
    send(owner, {:http2_up, self()})
    loop(%{state | socket: socket, protocol_state: proto_state})
  end

  @spec down(State.t, :normal | :closed | {:error, any}) :: no_return
  defp down(%State{owner: owner, opts: opts} = state, reason) do
    send(owner, {:http2_down, self(), reason})
    retry(%{state | socket: nil}, Dict.get(opts, :retry, 5))
  end

  # loop

  @spec loop(State.t) :: no_return
  defp loop(%State{
    owner: _owner,
    host: host,
    port: port,
    opts: _opts,
    socket: socket,
    transport: transport,
    protocol_state: proto_state
    } = state) do
      # Get the appropriate ok, closed, error message for this transport (tcp or ssl)
      {ok, closed, error} = transport.messages()

      # Receive one message at a time
      transport.setopts(socket, [{:active, :once}])
      receive do
        {^ok, socket, data} ->
          case Protocol.handle(data, proto_state) do
            :close ->
              transport.close(socket)
              down(state, :normal)
            proto_state2 ->
              loop(%{state | protocol_state: proto_state2})
          end
        {^closed, socket} ->
          transport.close(socket)
          down(state, :closed)
        {^error, socket, reason} ->
          transport.close(socket)
          down(state, {:error, reason})
        {:request, _owner, stream_ref, method, path, headers, body} ->
          proto_state2 = Protocol.request(proto_state, stream_ref, method,
          host, port, path, headers, body)
          loop(%{state | protocol_state: proto_state2})
      end
  end
end
