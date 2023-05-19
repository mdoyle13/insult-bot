defmodule Elixirbot.Consumer do
  use Nostrum.Consumer
  alias Nostrum.Api

  @bot_id "1106323282678001724"

  # ignore all bot messages, including my own
  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) when msg.author.bot == true do
    :ignore
  end

  # handle @mention
  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) when length(msg.mentions) > 0 do
    if String.contains?(msg.content, @bot_id) do
      Api.start_typing(msg.channel_id)
      Api.create_message(msg.channel_id, content: "#{get_insult(msg.author.username)}", message_reference: %{message_id: msg.id})
    else
      :ignore
    end
  end

  # handle direct message
  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    # check the message channel, DM is type 1
    case Api.get_channel(msg.channel_id) do
      {:ok, %{type: 1}} ->
        Api.start_typing(msg.channel_id)
        Api.create_message(msg.channel_id, content: "#{get_insult(msg.author.username)}")
      _ ->
        :ignore
    end
  end

  # Default event handler, if you don't include this, your consumer WILL crash if
  # you don't have a method definition for each event type.
  def handle_event(_event) do
    :noop
  end

  defp get_insult(subject) do
    sanitized_subject = subject |> RemoveEmoji.sanitize()
    url = "https://trumpinsultgenerator.com/api/InsultGenerator?subject=#{sanitized_subject}"
    #response = HTTPoison.get!("https://evilinsult.com/generate_insult.php?lang=en&type=json")
    response = HTTPoison.get!(url)
    IO.inspect(response.body)
    data = Jason.decode!(response.body)
    data["insult"]
  end
end
