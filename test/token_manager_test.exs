defmodule ExMicrosoftBotTest.TokenManager do
  use ExUnit.Case, async: true
  use Mimic

  import Plug.Conn, only: [resp: 3]

  alias ExMicrosoftBot.Models.AuthData
  alias ExMicrosoftBot.TokenManager

  @bypass_port Application.fetch_env!(:ex_microsoftbot, Bypass) |> Keyword.fetch!(:port)

  setup do
    stub(Application, :get_env, fn :ex_microsoftbot, key ->
      case key do
        :using_bot_emulator ->
          false

        :auth_api_endpoint ->
          "http://localhost:#{@bypass_port}/botframework.com/oauth2/v2.0/token"

        _ ->
          nil
      end
    end)

    bypass = Bypass.open(port: @bypass_port)

    {:ok, bypass: bypass}
  end

  describe "getting refreshed state" do
    test "tracks metric for refresh token failures", %{bypass: bypass} do
      auth_data = %AuthData{app_id: "BOT_APP_ID", app_password: "BOT_APP_PASSWORD"}

      expect_bot_framework_unauthorized_request(bypass)

      expect_statsd_increment_failure("msbot_api.request.count", [
        "operation:refresh_token",
        "error_code:401"
      ])

      TokenManager.get_refreshed_state(auth_data, nil)
    end
  end

  defp expect_bot_framework_unauthorized_request(bypass_process) do
    Bypass.expect_once(bypass_process, "POST", "/botframework.com/oauth2/v2.0/token", fn conn ->
      resp(conn, 401, "Authorization has been denied for this request.")
    end)
  end

  defp expect_statsd_increment_failure(metric_name, tags) do
    expect(StatsOwl, :increment_failure, fn ^metric_name, opts ->
      assert tags == Keyword.get(opts, :tags)

      :ok
    end)
  end
end
