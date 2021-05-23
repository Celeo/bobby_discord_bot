defmodule Bot.Application do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Starting application")
    Supervisor.start_link([Bot.Supervisor], strategy: :one_for_one)
  end
end

defmodule Bot.Supervisor do
  use Supervisor
  require Logger

  def start_link(args \\ []) do
    Logger.info("Starting supervisor")
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    Supervisor.init([Bot.Consumer], strategy: :one_for_one)
  end
end

defmodule Bot.Consumer do
  use Nostrum.Consumer
  require Logger
  alias Nostrum.Api

  def start_link do
    Logger.info("Starting consumer")
    Consumer.start_link(__MODULE__)
  end

  defp handle_mention(msg) do
    author_is_bot =
      case msg.author.bot do
        true -> true
        _ -> false
      end

    mentions_me = Enum.any?(msg.mentions, fn m -> String.contains?(m.username, "Bobby B") end)

    if not author_is_bot and mentions_me do
      response = Enum.take_random(Data.quotes(), 1) |> Enum.at(0)
      Api.create_message!(msg.channel_id, response)
      true
    else
      false
    end
  end

  defp handle_call_name(msg) do
    # 0.05% chance
    if Enum.random(1..200) == 200 do
      Nostrum.Api.create_message!(
        msg.channel_id,
        content: "Bitch",
        message_reference: %{message_id: msg.id}
      )
    end
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    if not handle_mention(msg) do
      handle_call_name(msg)
    end
  end

  def handle_event(_event), do: :noop
end
