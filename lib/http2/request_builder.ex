defmodule HTTP2.RequestBuilder do
  @spec preface :: binary
  def preface do
    "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n"
  end

  @spec settings :: binary
  def settings do
    << 0 :: 24, 4 :: 8, 0 :: 8, 0 :: 1, 0 :: 31 >>
  end
end
