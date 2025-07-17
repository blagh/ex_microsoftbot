defmodule ExMicrosoftBot.Monitoring.HTTPClient do
  @moduledoc """
  Module for Monitoring HTTP Requests
  """

  require Logger

  alias ExMicrosoftBot.Monitoring.HttpRequest

  @doc """
  Instruments the HTTP request, measuring processing time and collecting status codes.

  ## Params

  - `request`: The HTTP request to be instrumented.
  - `http_func`: The function that performs the HTTP request.

  ## Returns

  - Returns whatever the HTTP call returns.
  """
  @spec instrument(HttpRequest.t(), function()) :: any()
  def instrument(%HttpRequest{} = request, http_func) do
    do_instrument(request, http_func)
  end

  @spec do_instrument(HttpRequest.t(), function()) :: any()
  defp do_instrument(
         %HttpRequest{
           operation: operation,
           method: method,
           body_condition_func: body_condition_func
         } = request,
         http_func
       ) do
    tags = [
      "target_system:microsoft_bot_framework",
      "operation:#{operation}",
      "method:#{Atom.to_string(method)}"
    ]

    {nanoseconds, {new_tags, result}} =
      :timer.tc(fn ->
        result =
          http_func.()
          |> maybe_parse_body(request)

        more_tags = handle_result(result, tags, body_condition_func)

        {more_tags, result}
      end)

    tags =
      tags
      |> Kernel.++(new_tags)
      |> Enum.map(&String.downcase/1)
      |> Enum.uniq()

    StatsOwl.timing("outgoing_calls", ceil(nanoseconds / 1000), tags: tags)

    result
  end

  defp maybe_parse_body(resp, %{parse_body_func: nil} = _req), do: resp

  defp maybe_parse_body(resp, %{parse_body_func: parse_body_func} = _req) do
    with {:ok, %{body: body} = result} <- resp,
         {:ok, parsed} <- parse_body_func.(body) do
      {:ok, %{result | body: parsed}}
    else
      _ -> resp
    end
  end

  defp handle_result(
         {:ok, %{status_code: _status_code} = result},
         tags,
         body_condition_func
       ) do
    record_status_code(result, tags, body_condition_func)
  end

  defp handle_result(%{status_code: _status_code} = result, tags, body_condition_func) do
    record_status_code(result, tags, body_condition_func)
  end

  defp handle_result(
         {:error, %HTTPoison.Error{reason: reason}} = _result,
         tags,
         _body_condition_func
       )
       when is_atom(reason) do
    Logger.error(tags_to_log_data(tags) <> " result=failure reason=#{reason} Received error")

    ["result:failure", "status_code:#{reason}", "reason:#{reason}"]
  end

  defp handle_result(
         {:error, %HTTPoison.Error{reason: reason}} = _result,
         tags,
         _body_condition_func
       ) do
    Logger.error(
      tags_to_log_data(tags) <>
        " result=failure Received error: #{reason |> inspect()}"
    )

    ["result:failure", "reason:http_poison_error"]
  end

  defp handle_result({:error, error} = _result, tags, _body_condition_func) do
    Logger.error(
      tags_to_log_data(tags) <>
        " result=failure Received error: #{error |> data_redactor().redact() |> inspect()}"
    )

    ["result:failure", "reason:unclassified_http_error"]
  end

  defp handle_result(result, tags, _body_condition_func) do
    Logger.info(
      tags_to_log_data(tags) <>
        " result=unknown Received response:  #{result |> data_redactor().redact() |> inspect()}"
    )

    ["result:unknown"]
  end

  defp record_status_code(
         %{status_code: _status_code, body: _body} = result,
         tags,
         body_condition_func
       )
       when not is_nil(body_condition_func) do
    {result_category, more_tags} = body_condition_func.(result)

    tags =
      more_tags
      |> Enum.map(fn {k, v} -> "#{k}:#{v}" |> String.downcase() end)
      |> Kernel.++(tags)
      |> Enum.uniq()

    log_and_return_result(result, tags, result_category)
  end

  defp record_status_code(%{status_code: status_code} = _result, tags, _body_condition_func) do
    Logger.info(tags_to_log_data(tags) <> " result=success Received response")
    ["result:success", "status_code:#{status_code}"] ++ tags
  end

  defp log_and_return_result(%{status_code: status_code} = _result, tags, result_category) do
    log_tags = tags_to_log_data(tags)
    Logger.info(log_tags <> " result=#{result_category} Received response")
    ["result:#{result_category}", "status_code:#{status_code}"] ++ tags
  end

  defp tags_to_log_data(tags),
    do: Enum.map_join(tags, " ", fn x -> String.replace(x, ":", "=") end)

  defp data_redactor(), do: Application.fetch_env!(:pd_ex_microsoftbot, :data_redactor)
end
