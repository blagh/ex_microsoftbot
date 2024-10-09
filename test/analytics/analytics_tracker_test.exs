defmodule ExMicrosoftBot.Analytics.AnalyticsTrackerTest do
  use ExUnit.Case, async: true
  use Mimic

  alias ExMicrosoftBot.Analytics.AnalyticsTracker
  alias ExMicrosoftBot.Analytics.AnalyticsMeta

  describe "track_retry/1" do
    test "successfully creates an histogram with the correct arguments" do
      analytics_meta = %AnalyticsMeta{
        operation: "operation",
        status: 429,
        has_retry_after: true,
        wait_time: 100
      }

      expect(StatsOwl, :histogram, fn metric_name, wait_time, tags: tags ->
        assert metric_name == "exmicrosoftbot.retry"
        assert wait_time == 100
        assert tags == ["operation_id:operation", "status:429", "has_retry_after:true"]

        :ok
      end)

      assert AnalyticsTracker.track_retry(analytics_meta) == :ok
    end

    test "fails to create an histogram" do
      analytics_meta = %AnalyticsMeta{
        operation: "operation",
        status: 429,
        has_retry_after: true,
        wait_time: 100
      }

      expect(StatsOwl, :histogram, fn _, _, _ ->
        {:error, :error}
      end)

      assert AnalyticsTracker.track_retry(analytics_meta) == {:error, :error}
    end
  end
end
