defmodule HTTP2.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: HTTP2.Supervisor)
  end

  def init([]) do
    children = [
      worker(HTTP2, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one, max_restarts: 10, max_seconds: 10)
  end

end
