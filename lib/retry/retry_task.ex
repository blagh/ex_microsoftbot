defmodule ExMicrosoftBot.Retry.RetryTask do
  @moduledoc """
  This module implements Retry logic for MsTeams API calls,
  handling scenarios where API requests may need to be retried due to transient errors or rate-limiting responses from the server.
  @see [Documentation](https://learn.microsoft.com/en-us/microsoftteams/platform/bots/how-to/conversations/conversation-messages?tabs=dotnet1%2Capp-manifest-v112-or-later%2Cdotnet2%2Cdotnet3%2Cdotnet4%2Cdotnet5%2Cdotnet#status-codes-retry-guidance)

  ## Configuration
    Both the number of retries and the initial time to wait before retrying can be configured in `config.exs`:
    ```
      config :ex_microsoftbot,
       retries_count: 5,
        wait_time: 100
    ```
    If not configured, the default values are 5 retries and 100ms of initial wait time.

    ## Usage
    To use this module, you need to pass a function that returns a tuple with the HTTPoison response and the operation name.
    The function will be executed and if it fails, it will be retried with exponential backoff. The number of retries and the initial time to wait before retrying can be configured in `config.exs`.

    ```
      ExMicrosoftBot.Retry.RetryTask.start(
        fn -> ExMicrosoftBot.Client.get("https://microsoftbot.com/v3/conversations/123") end
      ),
      "operation_name"
    ```
  """

  alias ExMicrosoftBot.Analytics.AnalyticsMeta
  alias ExMicrosoftBot.Analytics.AnalyticsTracker
  alias ExMicrosoftBot.Retry.RetryTaskMeta, as: RetryMeta
  require Logger

  @two_hundreth_of_second 200

  @default_retry_meta %RetryMeta{
    current_retry: 0,
    max_retries: Application.compile_env(:ex_microsoftbot, :retries_count, 3),
    wait_time: Application.compile_env(:ex_microsoftbot, :wait_time, @two_hundreth_of_second)
  }

  # The header name returned when the server sends a 429 status code
  @retry_after_header "Retry-After"

  # The status codes that are retryable according to microsoft documentation
  @retryable_status_codes [412, 429, 502, 503, 504]

  @type response_t :: {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}

  @doc """
    Starts a task that retries the given action if it fails.

    # Arguments
    * `action` - the function to execute
    * `operation` - the id of the operation being executed
    * `retry_meta` - metadata for the retry task
  """
  @spec start(
          action :: (... -> response_t()),
          operation :: String.t(),
          retry_meta :: RetryMeta.t()
        ) ::
          response_t()
  def start(
        action,
        operation,
        retry_meta \\ @default_retry_meta
      ) do
    action.()
    |> handle_action_response(action, operation, retry_meta)
  end

  @spec handle_action_response(
          response :: response_t(),
          action :: fun(),
          operation :: String.t(),
          retry_meta :: RetryMeta.t()
        ) :: response_t()
  defp handle_action_response(
         {:ok, %{status_code: status_code, headers: headers}} = response,
         action,
         operation,
         %RetryMeta{
           current_retry: current_retry,
           max_retries: max_retries
         } = retry_meta
       )
       when status_code in @retryable_status_codes do
    has_retry_after = has_retry_after(headers)

    new_wait_time =
      if has_retry_after do
        get_retry_after_value(headers)
      else
        maybe_apply_exp_backoff(retry_meta)
      end

    AnalyticsTracker.track_retry(
      AnalyticsMeta.new(%{
        operation: operation,
        status: status_code,
        has_retry_after: has_retry_after,
        wait_time: new_wait_time
      })
    )

    Logger.info(
      "target_system=microsoftbot Response=#{inspect(response)} Retry in #{new_wait_time} ms"
    )

    maybe_start_retry(
      action,
      operation,
      RetryMeta.new(%{
        current_retry: current_retry,
        max_retries: max_retries,
        wait_time: new_wait_time
      }),
      response
    )
  end

  defp handle_action_response(
         {:ok, %{status_code: status_code}} = response,
         _action,
         _operation,
         _retry_meta
       )
       when status_code not in @retryable_status_codes do
    response
  end

  defp handle_action_response(
         {:error, _} = response,
         action,
         operation,
         %RetryMeta{
           current_retry: current_retry,
           max_retries: max_retries,
           wait_time: wait_time
         } = retry_meta
       ) do
    new_wait_time = maybe_apply_exp_backoff(retry_meta)

    AnalyticsTracker.track_retry(
      AnalyticsMeta.new(%{
        operation: operation,
        status: nil,
        has_retry_after: false,
        wait_time: wait_time
      })
    )

    maybe_start_retry(
      action,
      operation,
      RetryMeta.new(%{
        current_retry: current_retry,
        max_retries: max_retries,
        wait_time: new_wait_time
      }),
      response
    )
  end

  @spec maybe_start_retry(
          action :: fun(),
          operation :: String.t(),
          retry_meta :: RetryMeta.t(),
          response :: response_t()
        ) ::
          response_t()
  defp maybe_start_retry(
         _action,
         _operation,
         %RetryMeta{
           current_retry: current_retry,
           max_retries: max_retries
         },
         response
       )
       when current_retry == max_retries do
    Logger.info(
      "[Retry limit] has failed after exceeding max retries with the following response: #{inspect(response, pretty: true)}"
    )

    response
  end

  defp maybe_start_retry(
         action,
         operation,
         %RetryMeta{
           current_retry: current_retry,
           max_retries: max_retries,
           wait_time: wait_time
         },
         _response
       ) do
    wait_before_retry(wait_time)

    start(
      action,
      operation,
      RetryMeta.new(%{
        current_retry: current_retry + 1,
        max_retries: max_retries,
        wait_time: wait_time
      })
    )
  end

  defp maybe_apply_exp_backoff(%RetryMeta{wait_time: wait_time, current_retry: 0}), do: wait_time

  defp maybe_apply_exp_backoff(%RetryMeta{wait_time: wait_time}), do: wait_time * 2

  @spec wait_before_retry(integer()) :: :ok
  defp wait_before_retry(wait_time) do
    Process.sleep(wait_time)
  end

  defp has_retry_after(headers) do
    Enum.any?(headers, fn {key, _value} -> key == @retry_after_header end)
  end

  defp get_retry_after_value(headers) do
    headers
    |> Enum.find(fn {key, _value} -> key == @retry_after_header end)
    |> parse_and_convert()
  end

  defp parse_and_convert({_, value}) do
    case Integer.parse(value) do
      {int, _rest} -> convert_to_ms(int)
      _ -> nil
    end
  end

  defp convert_to_ms(seconds) when is_number(seconds) do
    seconds * 1_000
  end
end
