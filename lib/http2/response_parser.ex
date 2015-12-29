defmodule HTTP2.ResponseParser do
  @type streamid :: pos_integer
  @type fin :: :fin | :nofin
  @type head_fin :: :head_fin | :head_nofin
  @type exclusive :: :exclusive | :shared
  @type weight :: 1..256

  @type settings :: [header_table_size: non_neg_integer,
    enable_push: boolean,
    max_concurrent_stream: non_neg_integer,
    initial_window_size: 0..65535,
    max_frame_size: 16384..16777215,
    max_header_list_size: non_neg_integer]

  @type error :: :no_error
    | :protocol_error
    | :internal_error
    | :flow_control_error
    | :settings_timeout
    | :stream_closed
    | :frame_size_error
    | :refused_stream
    | :cancel
    | :compression_error
    | :connect_error
    | :enhance_your_calm
    | :inadequate_security
    | :http_1_1_required
    | :unknown_error

  @type format_error :: { :connection_error, error, String.t }
    | { :stream_error, streamid, error, String.t }

  @type frame :: { :data, streamid, fin, binary }
    | { :headers, streamid, fin, head_fin, binary }
    | { :headers, streamid, fin, head_fin, exclusive, streamid, weight, binary }
    | { :priority, streamid, exclusive, streamid, weight }
    | { :rst_stream, streamid, error }
    | { :settings, settings }
    | :settings_ack
    | { :push_promise, streamid, head_fin, streamid, binary }
    | { :ping, integer }
    | { :ping_ack, integer }
    | { :goaway, streamid, error, binary}
    | { :window_update, non_neg_integer }
    | { :window_update, streamid, non_neg_integer }
    | { :continuation, streamid, head_fin, binary }

  @spec parse(bitstring) :: {:ok, frame, bitstring} | format_error | :more

  ##
  ## DATA frame
  ##

  def parse(<< _ :: 24, 0 :: 8, _ :: 9, 0 :: 31, _ :: bitstring >>) do
    { :connection_error, :protocol_error, "DATA frames MUST be associated with a stream." }
  end

  def parse(<< length :: 24, 0 :: 8, _ :: 4, 1 :: 1, _ :: 35,
  pad_length :: 8, _ :: bitstring >>) when pad_length >= length do
    { :connection_error, :protocol_error, "Length of padding MUST be less than length of payload."}
  end

  ## No padding
  def parse(<< length :: 24, 0 :: 8, _ :: 4, 0 :: 1, _ :: 2, flag_end_stream :: 1,
  _ :: 1, stream_id :: 31, data :: binary-size(length), rest :: bitstring >>) do
    {:ok, {:data, stream_id, parse_fin(flag_end_stream), data}, rest}
  end

  ## Padding
  def parse(<< length :: 24, 0 :: 8, _ :: 4, 1 :: 1, _ :: 2, flag_end_stream :: 1,
  _ :: 1, stream_id :: 31, pad_length :: 8, rest :: bitstring >>)
    when byte_size(rest) >= length - 1 do
      payload_length = length - pad_length
      case rest do
        << data :: binary-size(payload_length), 0 :: binary-size(pad_length), rest :: bitstring >> ->
          {:ok, {:data, stream_id, parse_fin(flag_end_stream), data}, rest}
        _ ->
          { :connection_error, :protocol_error, "Padding octets MUST be set to zero." }
      end
  end

  ##
  ## HEADERS frame
  ##

  def parse(<< _ :: 24, 1 :: 8, _ :: 9, 0 :: 31, _ :: bitstring >>) do
    { :connection_error, :protocol_error, "HEADERS frames MUST be associated with a stream." }
  end

  def parse(<< length :: 24, 1 :: 8, _ :: 4, 1 :: 1, _ :: 35,
  pad_length :: 8, _ :: bitstring >>) when pad_length >= length do
    { :connection_error, :protocol_error, "Length of padding MUST be less than length of payload." }
  end

  def parse(<< length :: 24, 1 :: 8, _ :: 2, 1 :: 1, _ :: 1, 1 :: 1, _ :: 35,
  pad_length :: 8, _ :: bitstring >>) when pad_length >= length - 5 do
    { :connection_error, :protocol_error, "Length of padding MUST be less than length of payload." }
  end

  ## No padding, no priority
  def parse(<< length :: 24, 1 :: 8, _ :: 2, 0 :: 1, _ :: 1, 0 :: 1,
  flag_end_headers :: 1, _ :: 1, flag_end_stream :: 1, _ :: 1, stream_id :: 31,
  header_block_fragment :: binary-size(length), rest :: bitstring >>) do
    {:ok, {:headers, stream_id, parse_fin(flag_end_stream), parse_head_fin(flag_end_headers),
    header_block_fragment}, rest}
  end

  ## Padding, no priority
  def parse(<< length :: 24, 1 :: 8, _ :: 2, 0 :: 1, _ :: 1, 1 :: 1,
  flag_end_headers :: 1, _ :: 1, flag_end_stream :: 1, _ :: 1, stream_id :: 31,
  pad_length :: 8, rest :: bitstring >>) when byte_size(rest) >= length - 1 do
    payload_length = length - pad_length
    case rest do
      << header_block_fragment :: binary-size(payload_length), 0 :: binary-size(pad_length),
      rest :: bitstring >> ->
        {:ok, {:headers, stream_id, parse_fin(flag_end_stream), parse_head_fin(flag_end_headers),
        header_block_fragment}, rest}
      _ ->
        { :connection_error, :protocol_error, "Padding octets MUST be set to zero." }
    end
  end

  ## No padding, priority
  def parse(<< length :: 24, 1 :: 8, _ :: 2, 1 :: 1, _ :: 1, 0 :: 1,
  flag_end_headers :: 1, _ :: 1, flag_end_stream :: 1, _ :: 1, stream_id :: 31,
  e :: 1, dep_stream_id :: 31, weight :: 8, rest :: bitstring >>)
  when byte_size(rest) >= length - 5 do
    payload_length = length - 5
    << header_block_fragment :: binary-size(payload_length), rest :: bitstring >> = rest
    {:ok, {:headers, stream_id, parse_fin(flag_end_stream), parse_head_fin(flag_end_headers),
    parse_exclusive(e), dep_stream_id, weight + 1, header_block_fragment}, rest}
  end

  ## Padding, priority
  def parse(<< length :: 24, 1 :: 8, _ :: 2, 1 :: 1, _ :: 1, 1 :: 1,
  flag_end_headers :: 1, _ :: 1, flag_end_stream :: 1, _ :: 1, stream_id :: 31,
  pad_length :: 8, e :: 1, dep_stream_id :: 31, weight :: 8, rest :: bitstring >>)
  when byte_size(rest) >= length - 6 do
    payload_length = length - 6
    case rest do
      << header_block_fragment :: binary-size(payload_length), 0 :: binary-size(pad_length), rest :: bitstring >> ->
        {:ok, {:headers, stream_id, parse_fin(flag_end_stream), parse_head_fin(flag_end_headers),
        parse_exclusive(e), dep_stream_id, weight + 1, header_block_fragment}, rest}
      _ ->
        { :connection_error, :protocol_error, "Padding octets MUST be set to zero." }
    end
  end

  ##
  ## PRIORITY frame
  ##

  def parse(<< 5 :: 24, 2 :: 8, _ :: 9, 0 :: 31, _ :: bitstring >>) do
    { :connection_error, :protocol_error, "PRIORITY frames MUST be associated with a stream." }
  end

  def parse(<< 5 :: 24, 2 :: 8, _ :: 9, stream_id :: 31, e :: 1, dep_stream_id :: 31,
  weight :: 8, rest :: bitstring >>) do
    {:ok, {:priority, stream_id, parse_exclusive(e), dep_stream_id, weight + 1}, rest}
  end

  def parse(<< _ :: 24, 2 :: 8, _ :: 9, stream_id :: 31, _ :: bitstring >>) do
    { :stream_error, stream_id, :frame_size_error, "PRIORITY frames MUST be 5 bytes wide." }
  end

  ##
  ## RST_STREAM frame
  ##

  def parse(<< 4 :: 24, 3 :: 8, _ :: 9, 0 :: 31, _ :: bitstring >>) do
    { :connection_error, :protocol_error, "RST_STREAM frames MUST be associated with a stream." }
  end

  def parse(<< 4 :: 24, 3 :: 8, _ :: 9, stream_id :: 31, error_code :: 32, rest :: bitstring >>) do
    {:ok, {:rst_stream, stream_id, parse_error_code(error_code)}, rest}
  end

  def parse(<< _ :: 24, 3 :: 8, _ :: bitstring >>) do
    { :connection_error, :frame_size_error, "RST_STREAM frames MUST be 4 bytes wide." }
  end

  ##
  ## SETTINGS frame
  ##

  def parse(<< 0 :: 24, 4 :: 8, _ :: 7, 1 :: 1, _ :: 1, 0 :: 31, rest :: bitstring >>) do
    {:ok, :settings_ack, rest}
  end

  def parse(<< _ :: 24, 4 :: 8, _ :: 7, 1 :: 1, _ :: 1, 0 :: 31, _ :: bitstring >>) do
    { :connection_error, :frame_size_error, "SETTINGS frames with the ACK flag set MUST have a length of 0." }
  end

  def parse(<< length :: 24, 4 :: 8, _ :: 7, 0 :: 1, _ :: 1, 0 :: 31, _ :: bitstring >>)
  when rem(length, 6) != 0 do
    { :connection_error, :frame_size_error, "SETTINGS frames MUST have a length multiple of 6." }
  end

  def parse(<< length :: 24, 4 :: 8, _ :: 7, 0 :: 1, _ :: 1, 0 :: 31, rest :: bitstring >>)
  when byte_size(rest) >= length do
    parse_settings(rest, length, [])
  end

  def parse(<< _ :: 24, 4 :: 8, _ :: bitstring >>) do
    { :connection_error, :protocol_error, "SETTINGS frames MUST NOT be associated with a stream." }
  end

  ##
  ## PUSH_PROMISE frame
  ##

  def parse(<< _ :: 24, 5 :: 8, _ :: 9, 0 :: 31, _ :: bitstring >>) do
    { :connection_error, :protocol_error, "PUSH_PROMISE frames MUST be associated with a stream." }
  end

  ## No padding
  def parse(<< length :: 24, 5 :: 8, _ :: 4, 0 :: 1, flag_end_headers :: 1,
  _ :: 3, stream_id :: 31, promised_stream_id :: 31, rest :: bitstring >>)
  when byte_size(rest) >= length - 4 do
    payload_length = length - 4
    << header_block_fragment :: binary-size(payload_length), rest :: bitstring >> = rest
    {:ok, {:push_promise, stream_id, parse_head_fin(flag_end_headers), promised_stream_id,
    header_block_fragment}, rest}
  end

  ## Padding
  def parse(<< length :: 24, 5 :: 8, _ :: 4, 1 :: 1, flag_end_headers :: 1,
  _ :: 3, stream_id :: 31, pad_length :: 8, _ :: 1, promised_stream_id :: 31,
  rest :: bitstring >>) when byte_size(rest) >= length - 5 do
    payload_length = length - 5
    case rest do
      << header_block_fragment :: binary-size(payload_length),
      0 :: binary-size(pad_length), rest :: bitstring >> ->
        {:ok, {:push_promise, stream_id, parse_head_fin(flag_end_headers), promised_stream_id,
        header_block_fragment}, rest}
      _ ->
        { :connection_error, :protocol_error, "Padding octets MUST be set to zero." }
    end
  end

  ##
  ## PING frame
  ##

  def parse(<< 8 :: 24, 6 :: 8, _ :: 7, 1 :: 1, _ :: 1, 0 :: 31, opaque :: 64, rest :: bitstring >>) do
    {:ok, {:ping_ack, opaque}, rest}
  end

  def parse(<< 8 :: 24, 6 :: 8, _ :: 7, 0 :: 1, _ :: 1, 0 :: 31, opaque :: 64, rest :: bitstring >>) do
    {:ok, {:ping, opaque}, rest}
  end

  def parse(<< 8 :: 24, 6 :: 8, _ :: 104, _ :: bitstring >>) do
    { :connection_error, :protocol_error, "PING frames MUST NOT be associated with a stream." }
  end

  def parse(<< _ :: 24, 6 :: 8, _ :: bitstring >>) do
    { :connection_error, :frame_size_error, "PING frames MUST be 8 bytes wide." }
  end

  ##
  ## GOAWAY frame
  ##

  def parse(<< length :: 24, 7 :: 8, _ :: 9, 0 :: 31, _ :: 1, last_stream_id :: 31,
  error_code :: 32, rest :: bitstring >>) when byte_size(rest) >= length - 8 do
    payload_length = length - 8
    << debug_data :: binary-size(payload_length), rest :: bitstring >> = rest
    {:ok, {:goaway, last_stream_id, parse_error_code(error_code), debug_data}, rest}
  end

  def parse(<< _ :: 24, 7 :: 8, _ :: 40, _ :: bitstring >>) do
    { :connection_error, :protocol_error, "GOAWAY frames MUST NOT be associated with a stream." }
  end

  ##
  ## WINDOW_UPDATE frame
  ##

  def parse(<< 4 :: 24, 8 :: 8, _ :: 9, 0 :: 31, _ :: 1, 0 :: 31 >>) do
    { :connection_error, :protocol_error, "WINDOW_UPDATE frames MUST have a non-zero increment." }
  end

  def parse(<< 4 :: 24, 8 :: 8, _ :: 9, 0 :: 31, _ :: 1, increment :: 31, rest :: bitstring >>) do
    {:ok, {:window_update, increment}, rest}
  end

  def parse(<< 4 :: 24, 8 :: 8, _ :: 9, stream_id :: 31, _ :: 1, 0 :: 31, _ :: bitstring >>) do
    { :stream_error, stream_id, :protocol_error, "WINDOW_UPDATE frames MUST have a non-zero increment." }
  end

  def parse(<< 4 :: 24, 8 :: 8, _ :: 9, stream_id :: 31, _ :: 1, increment :: 31, rest :: bitstring >>) do
    {:ok, {:window_update, stream_id, increment}, rest}
  end

  def parse(<< _ :: 24, 8 :: 8, _ :: bitstring >>) do
    { :connection_error, :frame_size_error, "WINDOW_UPDATE frames MUST be 4 bytes wide." }
  end

  ##
  ## CONTINUATION frame
  ##

  def parse(<< _ :: 24, 9 :: 8, _ :: 9, 0 :: 31, _ :: bitstring >>) do
    { :connection_error, :protocol_error, "CONTINUATION frames MUST be associated with a stream." }
  end

  def parse(<< length :: 24, 9 :: 8, _ :: 5, flag_end_headers :: 1, _ :: 3,
  stream_id :: 31, header_block_fragment :: binary-size(length), rest :: bitstring >>) do
    {:ok, {:continuation, stream_id, parse_head_fin(flag_end_headers), header_block_fragment}, rest}
  end

  ##
  ## incomplete frames
  ##

  def parse(_) do
    :more
  end

  ##
  ## Settings Parsing
  ##

  @spec parse_settings(bitstring, non_neg_integer, Keyword.t) :: {:ok, {:settings, settings}, bitstring} | format_error

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
    { :connection_error, :protocol_error, "The SETTINGS_ENABLE_PUSH value MUST be 0 or 1." }
  end

  ## SETTINGS_MAX_CONCURRENT_STREAMS

  defp parse_settings(<< 3 :: 16, value :: 32, rest :: bitstring >>, length, settings) do
    parse_settings(rest, length - 6, Keyword.put(settings, :max_concurrent_stream, value))
  end

  ## SETTINGS_INITIAL_WINDOW_SIZE

  defp parse_settings(<< 4 :: 16, value :: 32, _ :: bitstring >>, _, _) when value > 0x7fffffff do
    { :connection_error, :flow_control_error, "The maximum SETTINGS_INITIAL_WINDOW_SIZE value is 0x7fffffff." }
  end

  defp parse_settings(<< 4 :: 16, value :: 32, rest :: bitstring >>, length, settings) do
    parse_settings(rest, length - 6, Keyword.put(settings, :initial_window_size, value))
  end

  ## SETTINGS_MAX_FRAME_SIZE

  defp parse_settings(<< 5 :: 16, value :: 32, _ :: bitstring >>, _, _) when value < 0x4000 or value > 0xFFFFFF do
    { :connection_error, :protocol_error, "The SETTINGS_MAX_FRAME_SIZE value MUST be between 0x4000 and 0xFFFFFF." }
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

  ##
  ## Helpers
  ##

  @spec parse_fin(0 | 1) :: fin
  defp parse_fin(0), do: :nofin
  defp parse_fin(1), do: :fin

  @spec parse_head_fin(0 | 1) :: head_fin
  defp parse_head_fin(0), do: :head_nofin
  defp parse_head_fin(1), do: :head_fin

  @spec parse_exclusive(0 | 1) :: exclusive
  defp parse_exclusive(0), do: :shared
  defp parse_exclusive(1), do: :exclusive

  @spec parse_error_code(non_neg_integer) :: error
  defp parse_error_code(0), do: :no_error
  defp parse_error_code(1), do: :protocol_error
  defp parse_error_code(2), do: :internal_error
  defp parse_error_code(3), do: :flow_control_error
  defp parse_error_code(4), do: :settings_timeout
  defp parse_error_code(5), do: :stream_closed
  defp parse_error_code(6), do: :frame_size_error
  defp parse_error_code(7), do: :refused_stream
  defp parse_error_code(8), do: :cancel
  defp parse_error_code(9), do: :compression_error
  defp parse_error_code(10), do: :connect_error
  defp parse_error_code(11), do: :enhance_your_calm
  defp parse_error_code(12), do: :inadequate_security
  defp parse_error_code(13), do: :http_1_1_required
  defp parse_error_code(_), do: :unknown_error

end
