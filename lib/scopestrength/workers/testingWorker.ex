defmodule Scopestrength.Workers.TestingWorker do
  use Oban.Worker, queue: :events
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"x" => x, "y"=> y}}) do
    sum= x + y
    IO.puts(sum)

    :ok
  end

end
