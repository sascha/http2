defmodule HTTP2.State do
  defstruct [
    :owner,
    :host,
    :port,
    :opts,
    :keepalive_ref,
    :socket,
    :transport,
    :protocol,
    :protocol_state
  ]
end
