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
            {:ok, protocol} ->
              IO.puts "connected with protocol #{protocol}"
            _ ->
              exit(:invalid_protocol)
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
          IO.puts "connected"
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

end
