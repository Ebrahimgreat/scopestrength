defmodule Scopestrength.Workers.FileMaker do
  use Oban.Worker, queue: :events
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"filename"=>filename, "text"=>text}}) do
    case File.open(filename,[:write, :utf8]) do
    {:ok, file}->IO.puts(file, text)
    File.close(file)
    {:error,reason}->IO.puts("Error opening a file,#{reason}")
    end

    end


end
