defmodule JSONRPC.Application do
  @moduledoc """
  Basic Application Supervisor
  """

  use Application

  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: JSONRPC.TaskSupervisor}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: JSONRPC.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
