defmodule HTTP2.RequestBuilder do
  @spec preface :: binary
  def preface do
    "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n"
  end
end
