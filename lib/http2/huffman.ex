defmodule HTTP2.Huffman do
  @code_by_byte %{
    << 0 >> => Macro.escape(<< 0x1ff8 :: 13 >>), << 1 >> => Macro.escape(<< 0x7fffd8 :: 23 >>),
    << 2 >> => Macro.escape(<< 0xfffffe2 :: 28 >>), << 3 >> => Macro.escape(<< 0xfffffe3 :: 28 >>),
    << 4 >> => Macro.escape(<< 0xfffffe4 :: 28 >>), << 5 >> => Macro.escape(<< 0xfffffe5 :: 28 >>),
    << 6 >> => Macro.escape(<< 0xfffffe6 :: 28 >>), << 7 >> => Macro.escape(<< 0xfffffe7 :: 28 >>),
    << 8 >> => Macro.escape(<< 0xfffffe8 :: 28 >>), << 9 >> => Macro.escape(<< 0xffffea :: 24 >>),
    << 10 >> => Macro.escape(<< 0x3ffffffc :: 30 >>), << 11 >> => Macro.escape(<< 0xfffffe9 :: 28 >>),
    << 12 >> => Macro.escape(<< 0xfffffea :: 28 >>), << 13 >> => Macro.escape(<< 0x3ffffffd :: 30 >>),
    << 14 >> => Macro.escape(<< 0xfffffeb :: 28 >>), << 15 >> => Macro.escape(<< 0xfffffec :: 28 >>),
    << 16 >> => Macro.escape(<< 0xfffffed :: 28 >>), << 17 >> => Macro.escape(<< 0xfffffee :: 28 >>),
    << 18 >> => Macro.escape(<< 0xfffffef :: 28 >>), << 19 >> => Macro.escape(<< 0xffffff0 :: 28 >>),
    << 20 >> => Macro.escape(<< 0xffffff1 :: 28 >>), << 21 >> => Macro.escape(<< 0xffffff2 :: 28 >>),
    << 22 >> => Macro.escape(<< 0x3ffffffe :: 30 >>), << 23 >> => Macro.escape(<< 0xffffff3 :: 28 >>),
    << 24 >> => Macro.escape(<< 0xffffff4 :: 28 >>), << 25 >> => Macro.escape(<< 0xffffff5 :: 28 >>),
    << 26 >> => Macro.escape(<< 0xffffff6 :: 28 >>), << 27 >> => Macro.escape(<< 0xffffff7 :: 28 >>),
    << 28 >> => Macro.escape(<< 0xffffff8 :: 28 >>), << 29 >> => Macro.escape(<< 0xffffff9 :: 28 >>),
    << 30 >> => Macro.escape(<< 0xffffffa :: 28 >>), << 31 >> => Macro.escape(<< 0xffffffb :: 28 >>),
    << 32 >> => Macro.escape(<< 0x14 :: 6 >>), << 33 >> => Macro.escape(<< 0x3f8 :: 10 >>),
    << 34 >> => Macro.escape(<< 0x3f9 :: 10 >>), << 35 >> => Macro.escape(<< 0xffa :: 12 >>),
    << 36 >> => Macro.escape(<< 0x1ff9 :: 13 >>), << 37 >> => Macro.escape(<< 0x15 :: 6 >>),
    << 38 >> => Macro.escape(<< 0xf8 :: 8 >>), << 39 >> => Macro.escape(<< 0x7fa :: 11 >>),
    << 40 >> => Macro.escape(<< 0x3fa :: 10 >>), << 41 >> => Macro.escape(<< 0x3fb :: 10 >>),
    << 42 >> => Macro.escape(<< 0xf9 :: 8 >>), << 43 >> => Macro.escape(<< 0x7fb :: 11 >>),
    << 44 >> => Macro.escape(<< 0xfa :: 8 >>), << 45 >> => Macro.escape(<< 0x16 :: 6 >>),
    << 46 >> => Macro.escape(<< 0x17 :: 6 >>), << 47 >> => Macro.escape(<< 0x18 :: 6 >>),
    << 48 >> => Macro.escape(<< 0x0 :: 5 >>), << 49 >> => Macro.escape(<< 0x1 :: 5 >>),
    << 50 >> => Macro.escape(<< 0x2 :: 5 >>), << 51 >> => Macro.escape(<< 0x19 :: 6 >>),
    << 52 >> => Macro.escape(<< 0x1a :: 6 >>), << 53 >> => Macro.escape(<< 0x1b :: 6 >>),
    << 54 >> => Macro.escape(<< 0x1c :: 6 >>), << 55 >> => Macro.escape(<< 0x1d :: 6 >>),
    << 56 >> => Macro.escape(<< 0x1e :: 6 >>), << 57 >> => Macro.escape(<< 0x1f :: 6 >>),
    << 58 >> => Macro.escape(<< 0x5c :: 7 >>), << 59 >> => Macro.escape(<< 0xfb :: 8 >>),
    << 60 >> => Macro.escape(<< 0x7ffc :: 15 >>), << 61 >> => Macro.escape(<< 0x20 :: 6 >>),
    << 62 >> => Macro.escape(<< 0xffb :: 12 >>), << 63 >> => Macro.escape(<< 0x3fc :: 10 >>),
    << 64 >> => Macro.escape(<< 0x1ffa :: 13 >>), << 65 >> => Macro.escape(<< 0x21 :: 6 >>),
    << 66 >> => Macro.escape(<< 0x5d :: 7 >>), << 67 >> => Macro.escape(<< 0x5e :: 7 >>),
    << 68 >> => Macro.escape(<< 0x5f :: 7 >>), << 69 >> => Macro.escape(<< 0x60 :: 7 >>),
    << 70 >> => Macro.escape(<< 0x61 :: 7 >>), << 71 >> => Macro.escape(<< 0x62 :: 7 >>),
    << 72 >> => Macro.escape(<< 0x63 :: 7 >>), << 73 >> => Macro.escape(<< 0x64 :: 7 >>),
    << 74 >> => Macro.escape(<< 0x65 :: 7 >>), << 75 >> => Macro.escape(<< 0x66 :: 7 >>),
    << 76 >> => Macro.escape(<< 0x67 :: 7 >>), << 77 >> => Macro.escape(<< 0x68 :: 7 >>),
    << 78 >> => Macro.escape(<< 0x69 :: 7 >>), << 79 >> => Macro.escape(<< 0x6a :: 7 >>),
    << 80 >> => Macro.escape(<< 0x6b :: 7 >>), << 81 >> => Macro.escape(<< 0x6c :: 7 >>),
    << 82 >> => Macro.escape(<< 0x6d :: 7 >>), << 83 >> => Macro.escape(<< 0x6e :: 7 >>),
    << 84 >> => Macro.escape(<< 0x6f :: 7 >>), << 85 >> => Macro.escape(<< 0x70 :: 7 >>),
    << 86 >> => Macro.escape(<< 0x71 :: 7 >>), << 87 >> => Macro.escape(<< 0x72 :: 7 >>),
    << 88 >> => Macro.escape(<< 0xfc :: 8 >>), << 89 >> => Macro.escape(<< 0x73 :: 7 >>),
    << 90 >> => Macro.escape(<< 0xfd :: 8 >>), << 91 >> => Macro.escape(<< 0x1ffb :: 13 >>),
    << 92 >> => Macro.escape(<< 0x7fff0 :: 19 >>), << 93 >> => Macro.escape(<< 0x1ffc :: 13 >>),
    << 94 >> => Macro.escape(<< 0x3ffc :: 14 >>), << 95 >> => Macro.escape(<< 0x22 :: 6 >>),
    << 96 >> => Macro.escape(<< 0x7ffd :: 15 >>), << 97 >> => Macro.escape(<< 0x3 :: 5 >>),
    << 98 >> => Macro.escape(<< 0x23 :: 6 >>), << 99 >> => Macro.escape(<< 0x4 :: 5 >>),
    << 100 >> => Macro.escape(<< 0x24 :: 6 >>), << 101 >> => Macro.escape(<< 0x5 :: 5 >>),
    << 102 >> => Macro.escape(<< 0x25 :: 6 >>), << 103 >> => Macro.escape(<< 0x26 :: 6 >>),
    << 104 >> => Macro.escape(<< 0x27 :: 6 >>), << 105 >> => Macro.escape(<< 0x6 :: 5 >>),
    << 106 >> => Macro.escape(<< 0x74 :: 7 >>), << 107 >> => Macro.escape(<< 0x75 :: 7 >>),
    << 108 >> => Macro.escape(<< 0x28 :: 6 >>), << 109 >> => Macro.escape(<< 0x29 :: 6 >>),
    << 110 >> => Macro.escape(<< 0x2a :: 6 >>), << 111 >> => Macro.escape(<< 0x7 :: 5 >>),
    << 112 >> => Macro.escape(<< 0x2b :: 6 >>), << 113 >> => Macro.escape(<< 0x76 :: 7 >>),
    << 114 >> => Macro.escape(<< 0x2c :: 6 >>), << 115 >> => Macro.escape(<< 0x8 :: 5 >>),
    << 116 >> => Macro.escape(<< 0x9 :: 5 >>), << 117 >> => Macro.escape(<< 0x2d :: 6 >>),
    << 118 >> => Macro.escape(<< 0x77 :: 7 >>), << 119 >> => Macro.escape(<< 0x78 :: 7 >>),
    << 120 >> => Macro.escape(<< 0x79 :: 7 >>), << 121 >> => Macro.escape(<< 0x7a :: 7 >>),
    << 122 >> => Macro.escape(<< 0x7b :: 7 >>), << 123 >> => Macro.escape(<< 0x7ffe :: 15 >>),
    << 124 >> => Macro.escape(<< 0x7fc :: 11 >>), << 125 >> => Macro.escape(<< 0x3ffd :: 14 >>),
    << 126 >> => Macro.escape(<< 0x1ffd :: 13 >>), << 127 >> => Macro.escape(<< 0xffffffc :: 28 >>),
    << 128 >> => Macro.escape(<< 0xfffe6 :: 20 >>), << 129 >> => Macro.escape(<< 0x3fffd2 :: 22 >>),
    << 130 >> => Macro.escape(<< 0xfffe7 :: 20 >>), << 131 >> => Macro.escape(<< 0xfffe8 :: 20 >>),
    << 132 >> => Macro.escape(<< 0x3fffd3 :: 22 >>), << 133 >> => Macro.escape(<< 0x3fffd4 :: 22 >>),
    << 134 >> => Macro.escape(<< 0x3fffd5 :: 22 >>), << 135 >> => Macro.escape(<< 0x7fffd9 :: 23 >>),
    << 136 >> => Macro.escape(<< 0x3fffd6 :: 22 >>), << 137 >> => Macro.escape(<< 0x7fffda :: 23 >>),
    << 138 >> => Macro.escape(<< 0x7fffdb :: 23 >>), << 139 >> => Macro.escape(<< 0x7fffdc :: 23 >>),
    << 140 >> => Macro.escape(<< 0x7fffdd :: 23 >>), << 141 >> => Macro.escape(<< 0x7fffde :: 23 >>),
    << 142 >> => Macro.escape(<< 0xffffeb :: 24 >>), << 143 >> => Macro.escape(<< 0x7fffdf :: 23 >>),
    << 144 >> => Macro.escape(<< 0xffffec :: 24 >>), << 145 >> => Macro.escape(<< 0xffffed :: 24 >>),
    << 146 >> => Macro.escape(<< 0x3fffd7 :: 22 >>), << 147 >> => Macro.escape(<< 0x7fffe0 :: 23 >>),
    << 148 >> => Macro.escape(<< 0xffffee :: 24 >>), << 149 >> => Macro.escape(<< 0x7fffe1 :: 23 >>),
    << 150 >> => Macro.escape(<< 0x7fffe2 :: 23 >>), << 151 >> => Macro.escape(<< 0x7fffe3 :: 23 >>),
    << 152 >> => Macro.escape(<< 0x7fffe4 :: 23 >>), << 153 >> => Macro.escape(<< 0x1fffdc :: 21 >>),
    << 154 >> => Macro.escape(<< 0x3fffd8 :: 22 >>), << 155 >> => Macro.escape(<< 0x7fffe5 :: 23 >>),
    << 156 >> => Macro.escape(<< 0x3fffd9 :: 22 >>), << 157 >> => Macro.escape(<< 0x7fffe6 :: 23 >>),
    << 158 >> => Macro.escape(<< 0x7fffe7 :: 23 >>), << 159 >> => Macro.escape(<< 0xffffef :: 24 >>),
    << 160 >> => Macro.escape(<< 0x3fffda :: 22 >>), << 161 >> => Macro.escape(<< 0x1fffdd :: 21 >>),
    << 162 >> => Macro.escape(<< 0xfffe9 :: 20 >>), << 163 >> => Macro.escape(<< 0x3fffdb :: 22 >>),
    << 164 >> => Macro.escape(<< 0x3fffdc :: 22 >>), << 165 >> => Macro.escape(<< 0x7fffe8 :: 23 >>),
    << 166 >> => Macro.escape(<< 0x7fffe9 :: 23 >>), << 167 >> => Macro.escape(<< 0x1fffde :: 21 >>),
    << 168 >> => Macro.escape(<< 0x7fffea :: 23 >>), << 169 >> => Macro.escape(<< 0x3fffdd :: 22 >>),
    << 170 >> => Macro.escape(<< 0x3fffde :: 22 >>), << 171 >> => Macro.escape(<< 0xfffff0 :: 24 >>),
    << 172 >> => Macro.escape(<< 0x1fffdf :: 21 >>), << 173 >> => Macro.escape(<< 0x3fffdf :: 22 >>),
    << 174 >> => Macro.escape(<< 0x7fffeb :: 23 >>), << 175 >> => Macro.escape(<< 0x7fffec :: 23 >>),
    << 176 >> => Macro.escape(<< 0x1fffe0 :: 21 >>), << 177 >> => Macro.escape(<< 0x1fffe1 :: 21 >>),
    << 178 >> => Macro.escape(<< 0x3fffe0 :: 22 >>), << 179 >> => Macro.escape(<< 0x1fffe2 :: 21 >>),
    << 180 >> => Macro.escape(<< 0x7fffed :: 23 >>), << 181 >> => Macro.escape(<< 0x3fffe1 :: 22 >>),
    << 182 >> => Macro.escape(<< 0x7fffee :: 23 >>), << 183 >> => Macro.escape(<< 0x7fffef :: 23 >>),
    << 184 >> => Macro.escape(<< 0xfffea :: 20 >>), << 185 >> => Macro.escape(<< 0x3fffe2 :: 22 >>),
    << 186 >> => Macro.escape(<< 0x3fffe3 :: 22 >>), << 187 >> => Macro.escape(<< 0x3fffe4 :: 22 >>),
    << 188 >> => Macro.escape(<< 0x7ffff0 :: 23 >>), << 189 >> => Macro.escape(<< 0x3fffe5 :: 22 >>),
    << 190 >> => Macro.escape(<< 0x3fffe6 :: 22 >>), << 191 >> => Macro.escape(<< 0x7ffff1 :: 23 >>),
    << 192 >> => Macro.escape(<< 0x3ffffe0 :: 26 >>), << 193 >> => Macro.escape(<< 0x3ffffe1 :: 26 >>),
    << 194 >> => Macro.escape(<< 0xfffeb :: 20 >>), << 195 >> => Macro.escape(<< 0x7fff1 :: 19 >>),
    << 196 >> => Macro.escape(<< 0x3fffe7 :: 22 >>), << 197 >> => Macro.escape(<< 0x7ffff2 :: 23 >>),
    << 198 >> => Macro.escape(<< 0x3fffe8 :: 22 >>), << 199 >> => Macro.escape(<< 0x1ffffec :: 25 >>),
    << 200 >> => Macro.escape(<< 0x3ffffe2 :: 26 >>), << 201 >> => Macro.escape(<< 0x3ffffe3 :: 26 >>),
    << 202 >> => Macro.escape(<< 0x3ffffe4 :: 26 >>), << 203 >> => Macro.escape(<< 0x7ffffde :: 27 >>),
    << 204 >> => Macro.escape(<< 0x7ffffdf :: 27 >>), << 205 >> => Macro.escape(<< 0x3ffffe5 :: 26 >>),
    << 206 >> => Macro.escape(<< 0xfffff1 :: 24 >>), << 207 >> => Macro.escape(<< 0x1ffffed :: 25 >>),
    << 208 >> => Macro.escape(<< 0x7fff2 :: 19 >>), << 209 >> => Macro.escape(<< 0x1fffe3 :: 21 >>),
    << 210 >> => Macro.escape(<< 0x3ffffe6 :: 26 >>), << 211 >> => Macro.escape(<< 0x7ffffe0 :: 27 >>),
    << 212 >> => Macro.escape(<< 0x7ffffe1 :: 27 >>), << 213 >> => Macro.escape(<< 0x3ffffe7 :: 26 >>),
    << 214 >> => Macro.escape(<< 0x7ffffe2 :: 27 >>), << 215 >> => Macro.escape(<< 0xfffff2 :: 24 >>),
    << 216 >> => Macro.escape(<< 0x1fffe4 :: 21 >>), << 217 >> => Macro.escape(<< 0x1fffe5 :: 21 >>),
    << 218 >> => Macro.escape(<< 0x3ffffe8 :: 26 >>), << 219 >> => Macro.escape(<< 0x3ffffe9 :: 26 >>),
    << 220 >> => Macro.escape(<< 0xffffffd :: 28 >>), << 221 >> => Macro.escape(<< 0x7ffffe3 :: 27 >>),
    << 222 >> => Macro.escape(<< 0x7ffffe4 :: 27 >>), << 223 >> => Macro.escape(<< 0x7ffffe5 :: 27 >>),
    << 224 >> => Macro.escape(<< 0xfffec :: 20 >>), << 225 >> => Macro.escape(<< 0xfffff3 :: 24 >>),
    << 226 >> => Macro.escape(<< 0xfffed :: 20 >>), << 227 >> => Macro.escape(<< 0x1fffe6 :: 21 >>),
    << 228 >> => Macro.escape(<< 0x3fffe9 :: 22 >>), << 229 >> => Macro.escape(<< 0x1fffe7 :: 21 >>),
    << 230 >> => Macro.escape(<< 0x1fffe8 :: 21 >>), << 231 >> => Macro.escape(<< 0x7ffff3 :: 23 >>),
    << 232 >> => Macro.escape(<< 0x3fffea :: 22 >>), << 233 >> => Macro.escape(<< 0x3fffeb :: 22 >>),
    << 234 >> => Macro.escape(<< 0x1ffffee :: 25 >>), << 235 >> => Macro.escape(<< 0x1ffffef :: 25 >>),
    << 236 >> => Macro.escape(<< 0xfffff4 :: 24 >>), << 237 >> => Macro.escape(<< 0xfffff5 :: 24 >>),
    << 238 >> => Macro.escape(<< 0x3ffffea :: 26 >>), << 239 >> => Macro.escape(<< 0x7ffff4 :: 23 >>),
    << 240 >> => Macro.escape(<< 0x3ffffeb :: 26 >>), << 241 >> => Macro.escape(<< 0x7ffffe6 :: 27 >>),
    << 242 >> => Macro.escape(<< 0x3ffffec :: 26 >>), << 243 >> => Macro.escape(<< 0x3ffffed :: 26 >>),
    << 244 >> => Macro.escape(<< 0x7ffffe7 :: 27 >>), << 245 >> => Macro.escape(<< 0x7ffffe8 :: 27 >>),
    << 246 >> => Macro.escape(<< 0x7ffffe9 :: 27 >>), << 247 >> => Macro.escape(<< 0x7ffffea :: 27 >>),
    << 248 >> => Macro.escape(<< 0x7ffffeb :: 27 >>), << 249 >> => Macro.escape(<< 0xffffffe :: 28 >>),
    << 250 >> => Macro.escape(<< 0x7ffffec :: 27 >>), << 251 >> => Macro.escape(<< 0x7ffffed :: 27 >>),
    << 252 >> => Macro.escape(<< 0x7ffffee :: 27 >>), << 253 >> => Macro.escape(<< 0x7ffffef :: 27 >>),
    << 254 >> => Macro.escape(<< 0x7fffff0 :: 27 >>), << 255 >> => Macro.escape(<< 0x3ffffee :: 26 >>),
    << 256 >> => Macro.escape(<< 0x3fffffff :: 30 >>)
  }

  for {byte, code} <- @code_by_byte do
    defp code_for_byte(unquote(byte)), do: unquote(code)

    defp byte_for_code(<< unquote(code), rest :: bitstring >>) do
      { unquote(byte), rest }
    end
  end

  defp byte_for_code(input), do: { :no_match, input }

  @spec encode(binary) :: binary
  def encode(input) do
    encode(input, <<>>)
  end

  defp encode(<< head :: binary-size(1), rest :: binary >>, encoded) do
    encode(rest, << encoded :: bitstring, code_for_byte(head) :: bitstring >>)
  end

  defp encode(_, encoded) when is_binary(encoded), do: encoded

  defp encode(_, encoded) do
    missing_bits = 8 - rem(bit_size(encoded), 8)
    << padding :: size(missing_bits), _ :: bitstring >> = code_for_byte(<< 256 >>)
    << encoded :: bitstring, padding :: size(missing_bits) >>
  end

  @spec decode(binary) :: binary
  def decode(input) do
    decode(input, <<>>)
  end

  defp decode(input, decoded) do
    case byte_for_code(input) do
      { :no_match, rest } ->
        padding_size = bit_size(rest)
        if padding_size > 7 do
          { :decoding_error, "Padding is larger than 7 bits" }
        else
          # Get most significant bits of EOS
          << eos :: size(padding_size), _ :: bitstring >> = code_for_byte(<< 256 >>)
          case rest do
            << ^eos :: size(padding_size) >> ->
              decoded
            _ ->
              { :decoding_error, "Padding does not match most significant bits of EOS" }
          end
        end
      { byte, rest } ->
        decode(rest, << decoded :: binary, byte :: binary >>)
    end
  end
end
