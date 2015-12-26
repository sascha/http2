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

  def handle(data, %HTTP2.Protocol{buffer: buffer} = state) do
    handle_loop(buffer <> data, %{state | buffer: <<>>})
  end

  defp handle_loop(data, state) do
    case parse(data) do
      {:ok, frame, rest} ->
        IO.puts("got a complete frame")
      :more ->
        %{state | buffer: data}
    end
  end

  # Parsing

  # TODO: Replace `any` with actual type
  @spec parse(bitstring) :: {:ok, any, bitstring} | any

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
  defp parse(<< length :: 24, 0 :: 8, _ :: 4, 0 :: 1, _ :: 2, flag_end_stream :: 1,
  _ :: 1, stream_id :: 31, data :: binary-size(length), rest :: bitstring >>) do
    # TODO
    {:ok, nil, rest}
  end

  ## Padding
  defp parse(<< length :: 24, 0 :: 8, _ :: 4, 1 :: 1, _ :: 2, flag_end_stream :: 1,
  _ :: 1, stream_id :: 31, pad_length :: 8, rest :: bitstring >>)
    when byte_size(rest) >= length - 1 do
      payload_length = length - pad_length
      case rest do
        << data :: binary-size(payload_length), 0 :: binary-size(pad_length), rest :: bitstring >> ->
          # TODO
          {:ok, nil, rest}
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
  header_block_fragment :: binary-size(length), rest :: bitstring >>) do
    # TODO
    {:ok, nil, rest}
  end

  ## Padding, no priority
  defp parse(<< length :: 24, 1 :: 8, _ :: 2, 0 :: 1, _ :: 1, 1 :: 1,
  flag_end_headers :: 1, _ :: 1, flag_end_stream :: 1, _ :: 1, stream_id :: 31,
  pad_length :: 8, rest :: bitstring >>) when byte_size(rest) >= length - 1 do
    payload_length = length - pad_length
    case rest do
      << header_block_fragment :: binary-size(payload_length), 0 :: binary-size(pad_length),
      rest :: bitstring >> ->
        # TODO
        {:ok, nil, rest}
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
    payload_length = length - 5
    << header_block_fragment :: binary-size(payload_length), rest :: bitstring >> = rest
    # TODO
    {:ok, nil, rest}
  end

  ## Padding, priority
  defp parse(<< length :: 24, 1 :: 8, _ :: 2, 1 :: 1, _ :: 1, 1 :: 1,
  flag_end_headers :: 1, _ :: 1, flag_end_stream :: 1, _ :: 1, stream_id :: 31,
  pad_length :: 8, e :: 1, dep_stream_id :: 31, weight :: 8, rest :: bitstring >>)
  when byte_size(rest) >= length - 6 do
    payload_length = length - 6
    case rest do
      << header_block_fragment :: binary-size(payload_length), 0 :: binary-size(pad_length), rest :: bitstring >> ->
        # TODO
        {:ok, nil, rest}
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
  weight :: 8, rest :: bitstring >>) do
    # TODO
    {:ok, nil, rest}
  end

  defp parse(<< bad_length :: 24, 2 :: 8, _ :: 9, stream_id :: 31,
  _ :: binary-size(bad_length), rest :: bitstring >>) do
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

  defp parse(<< 4 :: 24, 3 :: 8, _ :: 9, stream_id :: 31, error_code :: 32, rest :: bitstring >>) do
    # TODO
    {:ok, nil, rest}
  end

  defp parse(<< bad_length :: 24, 3 :: 8, _ :: 9, _ :: binary-size(bad_length), rest :: bitstring >>) do
    # TODO A RST_STREAM frame with a length other than 4 octets MUST be treated as
    # a connection error (Section 5.4.1) of type FRAME_SIZE_ERROR.
  end

  ##
  ## SETTINGS frame
  ##

  defp parse(<< 0 :: 24, 4 :: 8, _ :: 7, 1 :: 1, _ :: 1, 0 :: 31, rest :: bitstring >>) do
    # TODO ack
    {:ok, nil, rest}
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

  defp parse(<< length :: 24, 4 :: 8, _ :: 7, 0 :: 1, _ :: 1, 0 :: 31, rest :: bitstring >>)
  when byte_size(rest) >= length do
    parse_settings(rest, length, [])
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
  _ :: 3, stream_id :: 31, promised_stream_id :: 31, rest :: bitstring >>)
  when byte_size(rest) >= length - 4 do
    payload_length = length - 4
    << header_block_fragment :: binary-size(payload_length), rest :: bitstring >> = rest
    # TODO
    {:ok, nil, rest}
  end

  ## Padding
  defp parse(<< length :: 24, 5 :: 8, _ :: 4, 1 :: 1, flag_end_headers :: 1,
  _ :: 3, stream_id :: 31, pad_length :: 8, _ :: 1, promised_stream_id :: 31,
  rest :: bitstring >>) when byte_size(rest) >= length - 5 do
    payload_length = length - 5
    case rest do
      << header_block_fragment :: binary-size(payload_length),
      0 :: binary-size(pad_length), rest :: bitstring >> ->
        # TODO
        {:ok, nil, rest}
      _ ->
        # TODO A receiver is not obligated to verify padding but MAY treat non-zero
        # padding as a connection error (Section 5.4.1) of type PROTOCOL_ERROR.
    end
  end

  ##
  ## PING frame
  ##

  defp parse(<< 8 :: 24, 6 :: 8, _ :: 7, 1 :: 1, _ :: 1, 0 :: 31, opaque :: 64, rest :: bitstring >>) do
    # TODO ack
    {:ok, nil, rest}
  end

  defp parse(<< 8 :: 24, 6 :: 8, _ :: 7, 0 :: 1, _ :: 1, 0 :: 31, opaque :: 64, rest :: bitstring >>) do
    # TODO
    {:ok, nil, rest}
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
    << debug_data :: binary-size(payload_length), rest :: bitstring >> = rest
    # TODO
    {:ok, nil, rest}
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

  defp parse(<< 4 :: 24, 8 :: 8, _ :: 9, 0 :: 31, _ :: 1, increment :: 31, rest :: bitstring >>) do
    # TODO
    {:ok, nil, rest}
  end

  defp parse(<< 4 :: 24, 8 :: 8, _ :: 9, stream_id :: 31, _ :: 1, 0 :: 31, _ :: bitstring >>) do
    # TODO A receiver MUST treat the receipt of a WINDOW_UPDATE frame with an
    # flow-control window increment of 0 as a stream error (Section 5.4.2) of
    # type PROTOCOL_ERROR; errors on the connection flow-control window MUST be
    # treated as a connection error (Section 5.4.1).
  end

  defp parse(<< 4 :: 24, 8 :: 8, _ :: 9, stream_id :: 31, _ :: 1, increment :: 31, rest :: bitstring >>) do
    # TODO
    {:ok, nil, rest}
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
  stream_id :: 31, header_block_fragment :: binary-size(length), rest :: bitstring >>) do
    # TODO
    {:ok, nil, rest}
  end

  ##
  ## incomplete frames
  ##

  defp parse(_) do
    :more
  end

  ##
  ## Settings Parsing
  ##

  # TODO: Replace `any` with actual type
  @spec parse_settings(bitstring, non_neg_integer, Keyword.t) :: {:ok, any, bitstring} | any

  defp parse_settings(rest, 0, settings) do
    IO.puts("received settings: #{inspect settings}")
    {:ok, {:settings, settings}, rest}
  end

  ## SETTINGS_HEADER_TABLE_SIZE

  defp parse_settings(<< 1 :: 16, value :: 32, rest :: bitstring >>, length, settings) do
    parse_settings(rest, length - 6, Keyword.put(settings, :header_table_size, value))
  end

  ## SETTINGS_ENABLE_PUSH

  defp parse_settings(<< 2 :: 16, 0 :: 32, rest :: bitstring >>, length, settings) do
    parse_settings(rest, length - 6, Keyword.put(settings, :enable_push, false))
  end

  defp parse_settings(<< 2 :: 16, 1 :: 32, rest :: bitstring >>, length, settings) do
    parse_settings(rest, length - 6, Keyword.put(settings, :enable_push, true))
  end

  defp parse_settings(<< 2 :: 16, _ :: 32, _ :: bitstring >>, _, _) do
    # TODO Any value other than 0 or 1 MUST be treated as a connection error
    # (Section 5.4.1) of type PROTOCOL_ERROR.
  end

  ## SETTINGS_MAX_CONCURRENT_STREAMS

  defp parse_settings(<< 3 :: 16, value :: 32, rest :: bitstring >>, length, settings) do
    parse_settings(rest, length - 6, Keyword.put(settings, :max_concurrent_stream, value))
  end

  ## SETTINGS_INITIAL_WINDOW_SIZE

  defp parse_settings(<< 4 :: 16, value :: 32, _ :: bitstring >>, _, _) when value > 0x7fffffff do
    # TODO Values above the maximum flow-control window size of 2^31-1 MUST be
    # treated as a connection error (Section 5.4.1) of type FLOW_CONTROL_ERROR.
  end

  defp parse_settings(<< 4 :: 16, value :: 32, rest :: bitstring >>, length, settings) do
    parse_settings(rest, length - 6, Keyword.put(settings, :initial_window_size, value))
  end

  ## SETTINGS_MAX_FRAME_SIZE

  defp parse_settings(<< 5 :: 16, value :: 32, _ :: bitstring >>, _, _) when value < 0x4000 or value > 0xFFFFFF do
    # TODO The initial value is 2^14 (16,384) octets. The value advertised by an
    # endpoint MUST be between this initial value and the maximum allowed frame
    # size (2^24-1 or 16,777,215 octets), inclusive. Values outside this range
    # MUST be treated as a connection error (Section 5.4.1) of type PROTOCOL_ERROR.
  end

  defp parse_settings(<< 5 :: 16, value :: 32, rest :: bitstring >>, length, settings) do
    parse_settings(rest, length - 6, Keyword.put(settings, :max_frame_size, value))
  end

  ## SETTINGS_MAX_HEADER_LIST_SIZE

  defp parse_settings(<< 6 :: 16, value :: 32, rest :: bitstring >>, length, settings) do
    parse_settings(rest, length - 6, Keyword.put(settings, :max_header_list_size, value))
  end

  ## Other / Unknown

  defp parse_settings(<< _ :: 48, rest :: bitstring >>, length, settings) do
    parse_settings(rest, length - 6, settings)
  end
end
