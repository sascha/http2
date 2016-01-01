defmodule HTTP2.HPACK do
  @doc """
  Encodes the given integer `value` within an `prefix_length`-bit prefix using the
  algorithm described at https://httpwg.github.io/specs/rfc7541.html#integer.representation.

  ## Examples

      iex> HTTP2.HPACK.encode_integer(10, 5)
      <<10::size(5)>>

      iex> HTTP2.HPACK.encode_integer(1337, 5)
      <<252, 208, 10::size(5)>>

      iex> HTTP2.HPACK.encode_integer(42, 8)
      "*"

  """
  @spec encode_integer(non_neg_integer, 1..8) :: bitstring
  def encode_integer(value, prefix_length) when value >= 0 and prefix_length >= 1
  and prefix_length <= 8 do
    max_value = round(:math.pow(2, prefix_length) - 1)
    if value < max_value do
      << value :: size(prefix_length) >>
    else
      encode_integer(value - max_value, prefix_length,
      << max_value :: size(prefix_length) >>)
    end
  end

  @spec encode_integer(non_neg_integer, 1..8, bitstring) :: bitstring
  defp encode_integer(value, _, bytes) when value < 128 do
    << bytes :: bitstring, value >>
  end

  defp encode_integer(value, prefix_length, bytes) do
    encode_integer(round(value / 128), prefix_length, << bytes :: bitstring, (rem(value, 128) + 128) >>)
  end

  @doc """
  Decodes the integer encoded in `bytes` using an `prefix_length`-bit prefix and the
  algorithm described at https://httpwg.github.io/specs/rfc7541.html#integer.representation.

  ## Examples

      iex> HTTP2.HPACK.decode_integer(<< 10 :: 5 >>, 5)
      10

      iex> HTTP2.HPACK.decode_integer(<< 31 :: 5, 154, 10 >>, 5)
      1337

      iex> HTTP2.HPACK.decode_integer(<< 42 >>, 8)
      42
  """
  @spec decode_integer(bitstring, 1..8) :: non_neg_integer
  def decode_integer(bytes, prefix_length) when prefix_length >= 1 and prefix_length <= 8 do
    max_value = round(:math.pow(2, prefix_length) - 1)
    << value :: size(prefix_length), rest :: bitstring >> = bytes
    if value < max_value do
      value
    else
      decode_integer(rest, prefix_length, value, 0)
    end
  end

  @spec decode_integer(bitstring, 1..8, non_neg_integer, non_neg_integer) :: non_neg_integer
  defp decode_integer(<< 0 :: 1, i :: 7 >>, _, value, m) do
    value + (i * round(:math.pow(2, m)))
  end

  defp decode_integer(<< 1 :: 1, i :: 7, rest :: bitstring >>, prefix_length, value, m) do
    decode_integer(rest, prefix_length, value + (i * round(:math.pow(2, m))), m + 7)
  end
end
