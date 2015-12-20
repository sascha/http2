defmodule HTTP2.Application do
  use Application

  def start(_type, _args) do
    HTTP2.Supervisor.start_link
  end
end
