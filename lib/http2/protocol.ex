defmodule HTTP2.Protocol do
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

  @spec init(pid, :inet.socket | :ssl.sslsocket, module) :: HTTP2.Protocol.t
  def init(owner, socket, transport) do
    %HTTP2.Protocol{owner: owner, socket: socket, transport: transport}
  end

  @spec handle(binary, HTTP2.Protocol.t) :: HTTP2.Protocol.t | :close
  def handle(data, %HTTP2.Protocol{buffer: buffer} = state) do
    handle_loop(buffer <> data, %{state | buffer: <<>>})
  end

  @spec handle_loop(binary, HTTP2.Protocol.t) :: HTTP2.Protocol.t | :close
  defp handle_loop(data, state) do
    case HTTP2.ResponseParser.parse(data) do
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

  @spec handle_frame(binary, HTTP2.Protocol.t,
  HTTP2.ResponseParser.frame) :: HTTP2.Protocol.t | :close

  defp handle_frame(rest, state, frame) do
    # TODO
    handle_loop(rest, state)
  end

  ##
  ## Frame Sending
  ##

  @spec preface(HTTP2.Protocol.t) :: HTTP2.Protocol.t
  def preface(%HTTP2.Protocol{socket: socket, transport: transport} = state) do
    IO.puts "Sending preface"
    transport.send(socket, HTTP2.RequestBuilder.preface)
    IO.puts "Sending empty settings"
    transport.send(socket, HTTP2.RequestBuilder.settings)
    state
  end

  @spec settings(HTTP2.Protocol.t) :: HTTP2.Protocol.t
  def settings(%HTTP2.Protocol{socket: socket, transport: transport} = state) do
    transport.send(socket, HTTP2.RequestBuilder.settings)
    state
  end

end
