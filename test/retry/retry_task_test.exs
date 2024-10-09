defmodule RetryTaskTest do
  use ExUnit.Case, async: true

  alias ExMicrosoftBot.Retry.RetryTask
  alias ExMicrosoftBot.Retry.RetryTaskMeta
  @retries_count 3
  @wait_time 0

  test "returns parsed body when no error" do
    responses = first_time_ok()
    assert {:ok, %{}} = start_retry_task(responses)
  end

  test "retries specified number times" do
    agent_with_responses_pid = never_ok()

    expected_response = error()

    assert expected_response == start_retry_task(agent_with_responses_pid)
  end

  test "retries if network error occurs" do
    responses = create([error(), ok()])
    expected_response = ok()
    assert expected_response == start_retry_task(responses)
  end

  test "retries if 429 occurs" do
    responses = create([error_429(), ok()])
    expected_response = ok()
    assert expected_response == start_retry_task(responses)
  end

  defp start_retry_task(agent_with_responses_pid) do
    RetryTask.start(
      fn -> next_response(agent_with_responses_pid) end,
      "operation",
      RetryTaskMeta.new(%{current_retry: 0, max_retries: @retries_count, wait_time: @wait_time})
    )
  end

  defp create(responses) do
    {:ok, pid} = Agent.start_link(fn -> responses end)
    pid
  end

  defp never_ok(), do: create(for(_ <- 1..(@retries_count + 1), do: error()))

  defp error(), do: {:error, %HTTPoison.Error{id: "fail", reason: "network error"}}
  defp ok(), do: {:ok, %HTTPoison.Response{body: ~s({}), status_code: 200}}

  defp error_429(),
    do:
      {:ok, %HTTPoison.Response{body: ~s({}), status_code: 429, headers: [{"Retry-After", "1"}]}}

  defp first_time_ok(), do: create([ok()])

  defp next_response(pid) do
    resp = Agent.get(pid, &Kernel.hd/1)
    Agent.update(pid, &Kernel.tl/1)
    resp
  end
end
