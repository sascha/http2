defmodule HTTP2.State do
  defstruct [
    :owner,
    :host,
    :port,
    :opts,
    :socket,
    :transport,
    :protocol_state
  ]
  @type t :: %HTTP2.State{
    owner: pid,
    host: :inet.hostname,
    port: :inet.port_number,
    opts: Keyword.t,
    socket: :inet.socket | :ssl.sslsocket,
    transport: module,
    protocol_state: any
  }
end
