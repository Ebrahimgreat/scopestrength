defmodule Consumer do
  use GenStage
  require Logger
  alias Producer
  def start_link(args \\ "") do
    GenStage.start_link(__MODULE__, args)
  end
  def init(args) do
    Logger.info("init consuming")
    subscribe_options = [{Producer, min_demand: 0, max_demand: 10}]
    {:consumer, args, subscribe_to: subscribe_options}
  end
  def handle_events(events, _from, state) do
    Logger.info("Consumer State: #{state}")
    words = Enum.join(events)
    sentence = state <> words
    Logger.info("Final Stage: #{sentence}")
    {:noreply, [], sentence}

  end

end
