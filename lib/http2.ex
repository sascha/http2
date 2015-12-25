defmodule HTTP2 do
  def open(host, port, opts \\ []) do
    Task.Supervisor.start_child(HTTP2.Supervisor, __MODULE__, :init, [self(), host, port, opts])
  end

  def init(owner, host, port, opts) do
    retry = Dict.get(opts, :retry, 5)
    transport = case Dict.get(opts, :transport, default_transport(port)) do
      :tcp ->
        :ranch_tcp
      :ssl ->
        :ranch_ssl
    end
    connect(%HTTP2.State{
      owner: owner,
      host: host,
      port: port,
      opts: opts,
      transport: transport}, retry)
  end

  defp default_transport(443) do
    :ssl
  end

  defp default_transport(_) do
    :tcp
  end

  defp connect(%HTTP2.State{
    host: host,
    port: port,
    opts: opts,
    transport: transport = :ranch_ssl} = state, retries) do
      transportOpts = [:binary, {:active, false}, {:alpn_advertised_protocols, ["h2"]} | Dict.get(opts, :transport_opts, [])]
      case transport.connect(host, port, transportOpts) do
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

  defp connect(%HTTP2.State{
    host: host,
    port: port,
    opts: opts,
    transport: transport} = state, retries) do
      transportOpts = [:binary, {:active, false} | Dict.get(opts, :transport_opts, [])]
      case transport.connect(host, port, transportOpts) do
        {:ok, socket} ->
          IO.puts("connected without TLS")
          up(state ,socket)
        {:error, _} ->
          retry(state, retries)
      end
  end

  # Retry logic

  defp retry(_, 0) do
    exit(:gone)
  end

  defp retry(%HTTP2.State{opts: opts} = state, retries) do
    Process.send_after(self(), :retry, Dict.get(opts, :retry_timeout, 5000))
    receive do
      :retry ->
        connect(state, retries - 1)
    end
  end

  # Up/down logic

  defp up(%HTTP2.State{owner: owner, transport: transport} = state, socket) do
    protoState = HTTP2.Protocol.init(owner, socket, transport)
    send(owner, {:http2_up, self()})
    loop(%{state | socket: socket, protocol_state: protoState})
  end

  defp down(%HTTP2.State{owner: owner, opts: opts} = state, reason) do
    send(owner, {:http2_down, self(), reason})
    retry(%{state | socket: nil}, Dict.get(opts, :retry, 5))
  end

  # loop

  defp loop(%HTTP2.State{
    owner: _owner,
    host: _host,
    port: _port,
    opts: _opts,
    socket: socket,
    transport: transport,
    protocol_state: protoState
    } = state) do
      # Get the appropriate ok, closed, error message for this transport (tcp or ssl)
      {ok, closed, error} = transport.messages()

      # Receive one message at a time
      transport.setopts(socket, [{:active, :once}])

      receive do
        {^ok, socket, data} ->
          case HTTP2.Protocol.handle(data, protoState) do
            :close ->
              transport.close(socket)
              down(state, :normal)
            protoState2 ->
              loop(%{state | protocol_state: protoState2})
          end
        {^closed, socket} ->
          transport.close(socket)
          down(state, :closed)
        {^error, socket, reason} ->
          transport.close(socket)
          down(state, {:error, reason})
      end
  end
end
