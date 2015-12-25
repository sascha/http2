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
  _stream_id :: 31,
  _ :: bitstring >> = data) when byte_size(data) >= length + 9 do
    length2 = length + 9
    << frame :: binary-size(length2), rest :: bitstring >> = data
    {true, frame, rest}
  end

  defp split(_) do
    false
  end

  # Parsing

  ##
  ## DATA frame
  ##

  defp parse(<< _ :: 24, 0 :: 8, _ :: 9, 0 :: 31, _ :: bitstring >>) do
    # TODO: DATA frames MUST be associated with a stream. If a DATA frame is received
    # whose stream identifier field is 0x0, the recipient MUST respond with a connection
    # error (Section 5.4.1) of type PROTOCOL_ERROR.
  end

  defp parse(<< length :: 24, 0 :: 8, _ :: 4, 1 :: 1, _ :: 35,
  pad_length :: 8, _ :: bitstring >>) when pad_length >= length do
    # TODO: If the length of the padding is the length of the frame payload or greater,
    # the recipient MUST treat this as a connection error (Section 5.4.1) of type PROTOCOL_ERROR.
  end

  ## No padding
  defp parse(<< length :: 24, 0 :: 8, _ :: 4, 0 :: 1, _ :: 2, flag_end_stream :: 1, _ :: 1, stream_id :: 31, data :: binary-size(length) >>) do
    # TODO
  end

  ## Padding
  defp parse(<< length :: 24, 0 :: 8, _ :: 4, 1 :: 1, _ :: 2, flag_end_stream :: 1, _ :: 1, stream_id :: 31, pad_length :: 8, rest :: bitstring >>)
    when byte_size(rest) >= length - 1 do
      payloadLength = length - pad_length
      case rest do
        << data :: binary-size(payloadLength), 0 :: binary-size(pad_length), rest :: bitstring >> ->
          # TODO
          nil
        _ ->
          # TODO A receiver is not obligated to verify padding but MAY treat non-zero
          # padding as a connection error (Section 5.4.1) of type PROTOCOL_ERROR.
      end
  end

  ##
  ## HEADERS frame
  ##

  defp parse(<< _ :: 24, 1 :: 8, _ :: 9, 0 :: 31, _ :: bitstring >>) do
    # TODO: HEADERS frames MUST be associated with a stream. If a HEADERS frame is
    # received whose stream identifier field is 0x0, the recipient MUST respond with
    # a connection error (Section 5.4.1) of type PROTOCOL_ERROR.
  end

  defp parse(<< length :: 24, 1 :: 8, _ :: 4, 1 :: 1, _ :: 35,
  pad_length :: 8, _ :: bitstring >>) when pad_length >= length do
    # TODO: Padding that exceeds the size remaining for the header block fragment
    # MUST be treated as a PROTOCOL_ERROR.
  end

  defp parse(<< length :: 24, 1 :: 8, _ :: 2, 1 :: 1, _ :: 1, 1 :: 1, _ :: 35,
  pad_length :: 8, _ :: bitstring >>) when pad_length >= length - 5 do
    # TODO: Padding that exceeds the size remaining for the header block fragment
    # MUST be treated as a PROTOCOL_ERROR.
  end

  ## No padding, no priority
  defp parse(<< length :: 24, 1 :: 8, _ :: 2, 0 :: 1, _ :: 1, 0 :: 1,
  flag_end_headers :: 1, _ :: 1, flag_end_stream :: 1, _ :: 1, stream_id :: 31,
  data :: binary-size(length) >>) do
    # TODO
  end

  ## Padding, no priority
  defp parse(<< length :: 24, 1 :: 8, _ :: 2, 0 :: 1, _ :: 1, 1 :: 1,
  flag_end_headers :: 1, _ :: 1, flag_end_stream :: 1, _ :: 1, stream_id :: 31,
  pad_length :: 8, rest :: bitstring >>) when byte_size(rest) >= length - 1 do
    payloadLength = length - pad_length
    case rest do
      << data :: binary-size(payloadLength), 0 :: binary-size(pad_length), rest :: bitstring >> ->
        # TODO
        nil
      _ ->
        # TODO A receiver is not obligated to verify padding but MAY treat non-zero
        # padding as a connection error (Section 5.4.1) of type PROTOCOL_ERROR.
    end
  end

  ## No padding, priority
  defp parse(<< length :: 24, 1 :: 8, _ :: 2, 1 :: 1, _ :: 1, 0 :: 1,
  flag_end_headers :: 1, _ :: 1, flag_end_stream :: 1, _ :: 1, stream_id :: 31,
  e :: 1, dep_stream_id :: 31, weight :: 8, rest :: bitstring >>)
  when byte_size(rest) >= length - 5 do
    payloadLength = length - 5
    << data :: binary-size(payloadLength), rest :: bitstring >> = rest
    # TODO
  end

  ## Padding, priority
  defp parse(<< length :: 24, 1 :: 8, _ :: 2, 1 :: 1, _ :: 1, 1 :: 1,
  flag_end_headers :: 1, _ :: 1, flag_end_stream :: 1, _ :: 1, stream_id :: 31,
  pad_length :: 8, e :: 1, dep_stream_id :: 31, weight :: 8, rest :: bitstring >>)
  when byte_size(rest) >= length - 6 do
    payloadLength = length - 6
    case rest do
      << data :: binary-size(payloadLength), 0 :: binary-size(pad_length), rest :: bitstring >> ->
        # TODO
        nil
      _ ->
        # TODO A receiver is not obligated to verify padding but MAY treat non-zero
        # padding as a connection error (Section 5.4.1) of type PROTOCOL_ERROR.
    end
  end

  ##
  ## PRIORITY frame
  ##

  defp parse(<< 5 :: 24, 2 :: 8, _ :: 9, 0 :: 31, _ :: bitstring >>) do
    # TODO If a PRIORITY frame is received with a stream identifier of 0x0, the recipient
    # MUST respond with a connection error (Section 5.4.1) of type PROTOCOL_ERROR.
  end

  defp parse(<< 5 :: 24, 2 :: 8, _ :: 9, stream_id :: 31, e :: 1, dep_stream_id :: 31,
  weight :: 8, data :: bitstring >>) do
    # TODO
  end

  defp parse(<< bad_length :: 24, 2 :: 8, _ :: 9, stream_id :: 31,
  _ :: binary-size(bad_length) >>) do
    # TODO A PRIORITY frame with a length other than 5 octets MUST be treated as a
    # stream error (Section 5.4.2) of type FRAME_SIZE_ERROR.
  end

  ##
  ## RST_STREAM frame
  ##

  defp parse(<< 4 :: 24, 3 :: 8, _ :: 9, 0 :: 31, _ :: bitstring >>) do
    # TODO If a RST_STREAM frame is received with a stream identifier of 0x0, the
    # recipient MUST treat this as a connection error (Section 5.4.1) of type PROTOCOL_ERROR.
  end

  defp parse(<< 4 :: 24, 3 :: 8, _ :: 9, stream_id :: 31, error_code :: 32 >>) do
    # TODO
  end

  defp parse(<< bad_length :: 24, 3 :: 8, _ :: 9, _ :: binary-size(bad_length) >>) do
    # TODO A RST_STREAM frame with a length other than 4 octets MUST be treated as
    # a connection error (Section 5.4.1) of type FRAME_SIZE_ERROR.
  end

  ##
  ## SETTINGS frame
  ##

  defp parse(<< 0 :: 24, 4 :: 8, _ :: 7, 1 :: 1, _ :: 1, 0 :: 31 >>) do
    # TODO ack
  end

  defp parse(<< _ :: 24, 4 :: 8, _ :: 7, 1 :: 1, _ :: 1, 0 :: 31, _ :: bitstring >>) do
    # TODO Receipt of a SETTINGS frame with the ACK flag set and a length field value
    # other than 0 MUST be treated as a connection error (Section 5.4.1) of type FRAME_SIZE_ERROR.
  end

  defp parse(<< length :: 24, 4 :: 8, _ :: 7, 0 :: 1, _ :: 1, 0 :: 31, _ :: bitstring >>)
  when rem(length, 6) != 0 do
    # TODO A SETTINGS frame with a length other than a multiple of 6 octets MUST
    # be treated as a connection error (Section 5.4.1) of type FRAME_SIZE_ERROR.
  end

  defp parse(<< length :: 24, 4 :: 8, _ :: 7, 0 :: 1, _ :: 1, 0 :: 31, data :: bitstring >>)
  when byte_size(data) >= length do
    # TODO
  end

  defp parse(<< _ :: 24, 4 :: 8, _ :: bitstring >>) do
    # TODO If an endpoint receives a SETTINGS frame whose stream identifier field
    # is anything other than 0x0, the endpoint MUST respond with a connection error
    # (Section 5.4.1) of type PROTOCOL_ERROR.
  end

  ##
  ## PUSH_PROMISE frame
  ##

  defp parse(<< _ :: 24, 5 :: 8, _ :: 9, 0 :: 31, _ :: bitstring >>) do
    # TODO If the stream identifier field specifies the value 0x0, a recipient MUST
    # respond with a connection error (Section 5.4.1) of type PROTOCOL_ERROR.
  end

  ## No padding
  defp parse(<< length :: 24, 5 :: 8, _ :: 4, 0 :: 1, flag_end_headers :: 1,
  _ :: 3, stream_id :: 31, promised_stream_id :: 31, data :: bitstring >>)
  when byte_size(data) >= length - 4 do
    payload_length = length - 4
    << header_block_fragment :: binary-size(payload_length), rest :: bitstring >> = data
    # TODO
  end

  ## Padding
  defp parse(<< length :: 24, 5 :: 8, _ :: 4, 1 :: 1, flag_end_headers :: 1,
  _ :: 3, stream_id :: 31, pad_length :: 8, _ :: 1, promised_stream_id :: 31,
  data :: bitstring >>) when byte_size(data) >= length - 5 do
    payload_length = length - 5
    case data do
      << header_block_fragment :: binary-size(payload_length),
      0 :: binary-size(pad_length), rest :: bitstring >> ->
        # TODO
        nil
      _ ->
        # TODO A receiver is not obligated to verify padding but MAY treat non-zero
        # padding as a connection error (Section 5.4.1) of type PROTOCOL_ERROR.
    end
  end

  ##
  ## PING frame
  ##

  defp parse(<< 8 :: 24, 6 :: 8, _ :: 7, 1 :: 1, _ :: 1, 0 :: 31, opaque :: 64 >>) do
    # TODO ack
  end

  defp parse(<< 8 :: 24, 6 :: 8, _ :: 7, 0 :: 1, _ :: 1, 0 :: 31, opaque :: 64 >>) do
    # TODO
  end

  defp parse(<< 8 :: 24, 6 :: 8, _ :: 104, _ :: bitstring >>) do
    # TODO If a PING frame is received with a stream identifier field value other
    # than 0x0, the recipient MUST respond with a connection error (Section 5.4.1)
    # of type PROTOCOL_ERROR.
  end

  defp parse(<< _ :: 24, 6 :: 8, _ :: bitstring >>) do
    # TODO Receipt of a PING frame with a length field value other than 8 MUST
    # be treated as a connection error (Section 5.4.1) of type FRAME_SIZE_ERROR.
  end

  ##
  ## GOAWAY frame
  ##

  defp parse(<< length :: 24, 7 :: 8, _ :: 9, 0 :: 31, _ :: 1, last_stream_id :: 31,
  error_code :: 32, rest :: bitstring >>) when byte_size(rest) >= length - 8 do
    payload_length = length - 8
    << debug_data :: binary-size(payload_length), rest :: bitstring >> = data
    # TODO
  end

  defp parse(<< _ :: 24, 7 :: 8, _ :: 40, _ :: bitstring >>) do
    # TODO An endpoint MUST treat a GOAWAY frame with a stream identifier other
    # than 0x0 as a connection error (Section 5.4.1) of type PROTOCOL_ERROR.
  end

  ##
  ## WINDOW_UPDATE frame
  ##

  defp parse(<< 4 :: 24, 8 :: 8, _ :: 9, 0 :: 31, _ :: 1, 0 :: 31 >>) do
    # TODO A receiver MUST treat the receipt of a WINDOW_UPDATE frame with an
    # flow-control window increment of 0 as a stream error (Section 5.4.2) of
    # type PROTOCOL_ERROR; errors on the connection flow-control window MUST be
    # treated as a connection error (Section 5.4.1).
  end

  defp parse(<< 4 :: 24, 8 :: 8, _ :: 9, 0 :: 31, _ :: 1, increment :: 31 >>) do
    # TODO
  end

  defp parse(<< 4 :: 24, 8 :: 8, _ :: 9, stream_id :: 31, _ :: 1, 0 :: 31 >>) do
    # TODO A receiver MUST treat the receipt of a WINDOW_UPDATE frame with an
    # flow-control window increment of 0 as a stream error (Section 5.4.2) of
    # type PROTOCOL_ERROR; errors on the connection flow-control window MUST be
    # treated as a connection error (Section 5.4.1).
  end

  defp parse(<< 4 :: 24, 8 :: 8, _ :: 9, stream_id :: 31, _ :: 1, increment :: 31 >>) do
    # TODO
  end

  defp parse(<< _ :: 24, 8 :: 8, _ :: bitstring >>) do
    # TODO A WINDOW_UPDATE frame with a length other than 4 octets MUST be
    # treated as a connection error (Section 5.4.1) of type FRAME_SIZE_ERROR.
  end

  ##
  ## CONTINUATION frame
  ##

  defp parse(<< _ :: 24, 9 :: 8, _ :: 9, 0 :: 31, _ :: bitstring >>) do
    # TODO  If a CONTINUATION frame is received whose stream identifier field is
    # 0x0, the recipient MUST respond with a connection error (Section 5.4.1) of
    # type PROTOCOL_ERROR.
  end

  defp parse(<< length :: 24, 9 :: 8, _ :: 5, flag_end_headers :: 1, _ :: 3,
  stream_id :: 31, header_block_fragment :: binary-size(length) >>) do
    # TODO
  end

  ##
  ## incomplete frames
  ##

  defp parse(_) do
    # TODO
  end
end
