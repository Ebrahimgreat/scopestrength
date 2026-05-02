defmodule Scopestrength.Workers.TestingWorker2 do
  use Oban.Worker, queue: :default
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"x"=>x, "y"=> y}}) do
    multiply = x * y
    IO.puts(multiply)
  end
end
