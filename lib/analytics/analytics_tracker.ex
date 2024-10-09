defmodule ExMicrosoftBot.Analytics.AnalyticsTracker do
  @moduledoc """
    This module is responsible for tracking the analytics of the bot
  """

  @spec track_retry(analytics_meta :: ExMicrosoftBot.AnalyticsMeta.t()) :: Statix.on_send()
  def track_retry(analytics_meta) do
    tags = build_tags_from_meta(analytics_meta)

    StatsOwl.histogram("exmicrosoftbot.retry", analytics_meta.wait_time, tags: tags)
  end

  defp build_tags_from_meta(%{
         operation: operation,
         status: status,
         has_retry_after: has_retry_after
       }) do
    [
      "operation_id:#{sanitize(operation)}",
      "status:#{status}",
      "has_retry_after:#{has_retry_after}"
    ]
  end

  @spec sanitize(String.t()) :: String.t()
  def sanitize(text) when is_binary(text) do
    text
    |> String.trim()
    |> String.downcase()
  end
end
