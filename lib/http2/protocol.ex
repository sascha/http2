defmodule HTTP2.Protocol do
  alias HTTP2.ResponseParser
  alias HTTP2.RequestBuilder

  defstruct [
    owner: nil,
    socket: nil,
    transport: nil,
    buffer: <<>>
  ]

  @type t :: %HTTP2.Protocol{
    owner: pid,
    socket: :inet.socket | :ssl.sslsocket,
    transport: module,
    buffer: bitstring
  }

  @spec init(pid, :inet.socket | :ssl.sslsocket, module) :: t
  def init(owner, socket, transport) do
    %HTTP2.Protocol{owner: owner, socket: socket, transport: transport}
  end

  @spec handle(binary, t) :: t | :close
  def handle(data, %HTTP2.Protocol{buffer: buffer} = state) do
    handle_loop(buffer <> data, %{state | buffer: <<>>})
  end

  @spec handle_loop(binary, t) :: t | :close
  defp handle_loop(data, state) do
    case ResponseParser.parse(data) do
      {:ok, frame, rest} ->
        IO.puts("got a complete frame: #{inspect frame}")
        handle_frame(rest, state, frame)
      :more ->
        %{state | buffer: data}
    end
  end

  ##
  ## Frame Handling
  ##

  @spec handle_frame(binary, t, ResponseParser.frame) :: t | :close

  defp handle_frame(rest, state, frame) do
    # TODO
    handle_loop(rest, state)
  end

  ##
  ## Frame Sending
  ##

  @spec request(t, reference, iodata, :inet.hostname, :inet.port_number,
  iodata, HTTP2.headers, iodata) :: t
  def request(%HTTP2.Protocol{socket: socket, transport: transport} = state,
  stream_ref, method, host, port, path, headers \\ [], body \\ <<>>) do
    # TODO
    state
  end

  @spec preface(t) :: t
  def preface(%HTTP2.Protocol{socket: socket, transport: transport} = state) do
    IO.puts "Sending preface with empty settings frame"
    transport.send(socket, [
      RequestBuilder.preface,
      RequestBuilder.settings
    ])
    state
  end

  @spec settings(t) :: t
  def settings(%HTTP2.Protocol{socket: socket, transport: transport} = state) do
    transport.send(socket, RequestBuilder.settings)
    state
  end

end
