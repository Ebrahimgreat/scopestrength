defmodule Producer do
  use GenStage
  def start_link(sentence \\ "") do
    GenStage.start(__MODULE__, sentence, name: __MODULE__)
  end
  def init(inital_state) do
    {:producer, inital_state}
  end
  def handle_demand(demand, state) do
    IO.inspect("Demand: #{demand}, state: #{state}", label: "STATE")
    letters = state|> String.graphemes()
    letters_to_consume = Enum.take(letters, demand)
    sentence_left = String.slice(state, demand, length(letters))
    {:noreply, letters_to_consume, sentence_left}

  end

end
