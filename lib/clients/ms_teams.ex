defmodule ExMicrosoftBot.Client.MsTeams do
  @moduledoc """
  This module provides the Microsoft Teams specific functions.
  """

  import ExMicrosoftBot.Client, only: [get: 2, deserialize_response: 2]
  alias ExMicrosoftBot.Models
  alias ExMicrosoftBot.Models.ChannelAccount

  @doc """
  Lists conversations in a team.

  This function retrieves a list of conversations (channels) within a Microsoft Teams team.
  It corresponds to the Bot Framework Connector API endpoint for getting conversations.

  ## Parameters

  - `service_url` - The service URL for the Bot Framework Connector API
  - `team_id` - The unique identifier of the team to list conversations for
  - `continuationToken` - Optional. Token to retrieve the next set of results for paginated responses

  ## Returns

  Returns a response containing the list of conversations and optionally a continuation token
  for retrieving additional results.

  ## References

  - [Bot Framework REST Connector API - Get Conversations](https://learn.microsoft.com/en-us/azure/bot-service/rest-api/bot-framework-rest-connector-api-reference?view=azure-bot-service-4.0#get-conversations)

  ## Examples

    iex> conversations_list("https://smba.trafficmanager.net/amer/", "team123")
    {:ok, %{conversations: [...], continuationToken: "token456"}}

    iex> conversations_list("https://smba.trafficmanager.net/amer/", "team123", "token456")
    {:ok, %{conversations: [...]}}
  """
  @spec conversations_list(String.t(), String.t(), String.t() | nil) ::
          {:ok, %{conversations: [ChannelAccount.t()], continuationToken: String.t() | nil}}
  def conversations_list(service_url, team_id, continuationToken \\ nil) do
    api_endpoint = build_api_endpoint(service_url, team_id, continuationToken)

    decode_conversations = fn resp ->
      Poison.decode!(resp)
      |> Map.update("conversations", [], fn conversations ->
        conversations |> Models.ChannelAccount.parse() |> elem(1)
      end)
      |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
    end

    api_endpoint
    |> get(operation: "conversations_list")
    |> deserialize_response(decode_conversations)
  end

  defp build_api_endpoint(service_url, team_id, nil),
    do:
      String.trim_trailing(service_url, "/") <>
        "/v3/teams/#{URI.encode_www_form(team_id)}/conversations"

  defp build_api_endpoint(service_url, team_id, continuationToken),
    do:
      String.trim_trailing(service_url, "/") <>
        "/v3/teams/#{URI.encode_www_form(team_id)}/conversations?continuationToken=#{URI.encode_www_form(continuationToken)}"
end
