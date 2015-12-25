defmodule HTTP2.State do
  defstruct [
    :owner,
    :host,
    :port,
    :opts,
    :socket,
    :transport,
    :protocol,
    :protocol_state
  ]
end
