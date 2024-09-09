defmodule ExMicrosoftBotTest.TokenManager do
  use ExUnit.Case, async: true
  use Mimic

  import Plug.Conn, only: [resp: 3]

  alias ExMicrosoftBot.Models.AuthData
  alias ExMicrosoftBot.TokenManager

  setup do
    auth_data = %AuthData{app_id: "BOT_APP_ID", app_password: "BOT_APP_PASSWORD"}

    stub(Application, :get_env, fn :ex_microsoftbot, key ->
      case key do
        :using_bot_emulator ->
          false

        :auth_api_endpoint ->
          "http://localhost:#{BypassHelper.port()}/botframework.com/oauth2/v2.0/token"

        _ ->
          nil
      end
    end)

    stub(JOSE.JWT, :peek_payload, fn _jwt ->
      %JOSE.JWT{
        fields: %{"appid" => auth_data.app_id}
      }
    end)

    bypass = Bypass.open(port: BypassHelper.port())

    {:ok, bypass: bypass, auth_data: auth_data}
  end

  describe "getting refreshed state" do
    test "tracks metric for refresh token success", %{bypass: bypass, auth_data: auth_data} do
      expect_bot_framework_success_auth_request(bypass)

      expect_bot_api_tracking(:increment_success, [
        "operation:refresh_token"
      ])

      TokenManager.get_refreshed_state(auth_data, nil)
    end

    test "tracks metric for refresh token failures", %{bypass: bypass, auth_data: auth_data} do
      expect_bot_framework_unauthorized_request(bypass)

      expect_bot_api_tracking(:increment_failure, [
        "operation:refresh_token",
        "error_code:401"
      ])

      TokenManager.get_refreshed_state(auth_data, nil)
    end
  end

  defp expect_bot_framework_success_auth_request(bypass_process) do
    Bypass.expect_once(bypass_process, "POST", "/botframework.com/oauth2/v2.0/token", fn conn ->
      resp(conn, 200, Jason.encode!(%{access_token: "ACCESS_TOKEN", expires_in: 3600}))
    end)
  end

  defp expect_bot_framework_unauthorized_request(bypass_process) do
    Bypass.expect_once(bypass_process, "POST", "/botframework.com/oauth2/v2.0/token", fn conn ->
      resp(conn, 401, "Authorization has been denied for this request.")
    end)
  end

  defp expect_bot_api_tracking(fun, tags) do
    expect(StatsOwl, fun, fn "msbot_api.request.count", opts ->
      assert tags == Keyword.get(opts, :tags)

      :ok
    end)
  end
end
