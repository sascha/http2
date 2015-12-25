defmodule HTTP2.Protocol do
  defstruct [
    owner: nil,
    socket: nil,
    transport: nil,
    buffer: <<>>
  ]

  def init(owner, socket, transport) do
    %HTTP2.Protocol{owner: owner, socket: socket, transport: transport}
  end

  def handle(data, %HTTP2.Protocol{buffer: buffer} = state) do
    handle_loop(buffer <> data, %{state | buffer: <<>>})
  end

  defp handle_loop(data, state) do
    case split(data) do
      {true, frame, rest} ->
        IO.puts("got a complete frame")
        # TODO
      false ->
        %{state | buffer: data}
    end
  end

  defp split(<<
  length :: 24,
  _type :: 8,
  _flags :: 8,
  _ :: 1,
  _streamID :: 31,
  _ :: bitstring >> = data) when byte_size(data) >= length + 9 do
    length2 = length + 9
    << frame :: size(length2), rest :: bitstring >> = data
    {true, frame, rest}
  end

  defp split(_) do
    false
  end
end
