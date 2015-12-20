defmodule HTTP2.Application do
  use Application

  def start(_type, _args) do
    Task.Supervisor.start_link(name: HTTP2.Supervisor, max_restarts: 10, max_seconds: 10)
  end
end
