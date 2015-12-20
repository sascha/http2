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
              IO.puts "could not connect via SSL"
          end
        {:error, _} ->
          IO.puts "connection failed"
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
          IO.puts "connection failed"
      end
  end

end
