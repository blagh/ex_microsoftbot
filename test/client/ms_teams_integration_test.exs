defmodule ExMicrosoftBot.Client.MsTeamsIntegrationTest do
  use ExUnit.Case

  import Plug.Conn, only: [resp: 3, get_req_header: 2]

  alias ExMicrosoftBot.Models.ChannelAccount
  alias ExMicrosoftBot.Client.MsTeams

  describe "conversations_list/3" do
    setup do
      bypass = Bypass.open(port: BypassHelper.port())
      {:ok, bypass: bypass}
    end

    test "GETs the conversations list from the given serviceUrl without continuationToken", %{
      bypass: bypass
    } do
      team_id = "team123"

      Bypass.expect_once(
        bypass,
        "GET",
        "/v3/teams/#{URI.encode_www_form(team_id)}/conversations",
        fn conn ->
          assert conn |> get_req_header("content-type") |> List.first() == "application/json"
          assert conn |> get_req_header("accept") |> List.first() == "application/json"
          assert conn |> get_req_header("authorization") |> List.first() == "Bearer"

          response_body = %{
            "conversations" => [
              %{
                "id" => "conversation1",
                "name" => "General Channel",
                "aadObjectId" => "00000000-0000-0000-0000-000000000001"
              },
              %{
                "id" => "conversation2",
                "name" => "Development Channel",
                "aadObjectId" => "00000000-0000-0000-0000-000000000002"
              }
            ]
          }

          resp(conn, 200, Poison.encode!(response_body))
        end
      )

      assert {:ok, result} =
               MsTeams.conversations_list(
                 "http://localhost:#{BypassHelper.port()}",
                 team_id
               )

      assert %{conversations: conversations} = result
      assert length(conversations) == 2

      [%ChannelAccount{} = conv1, %ChannelAccount{} = conv2] = conversations

      assert conv1.id == "conversation1"
      assert conv1.name == "General Channel"
      assert conv1.aadObjectId == "00000000-0000-0000-0000-000000000001"

      assert conv2.id == "conversation2"
      assert conv2.name == "Development Channel"
      assert conv2.aadObjectId == "00000000-0000-0000-0000-000000000002"
    end

    test "GETs the conversations list from the given serviceUrl with continuationToken", %{
      bypass: bypass
    } do
      team_id = "team123"
      continuation_token = "next_page_token_123"

      Bypass.expect_once(
        bypass,
        "GET",
        "/v3/teams/team123/conversations",
        fn conn ->
          # Check that the continuation token is in the query parameters
          assert conn.query_string == "continuationToken=#{continuation_token}"
          assert conn |> get_req_header("content-type") |> List.first() == "application/json"
          assert conn |> get_req_header("accept") |> List.first() == "application/json"
          assert conn |> get_req_header("authorization") |> List.first() == "Bearer"

          response_body = %{
            "conversations" => [
              %{
                "id" => "conversation3",
                "name" => "Random Channel",
                "aadObjectId" => "00000000-0000-0000-0000-000000000003"
              }
            ],
            "continuationToken" => "final_page_token_456"
          }

          resp(conn, 200, Poison.encode!(response_body))
        end
      )

      assert {:ok, result} =
               MsTeams.conversations_list(
                 "http://localhost:#{BypassHelper.port()}",
                 team_id,
                 continuation_token
               )

      assert %{conversations: conversations, continuationToken: token} = result
      assert length(conversations) == 1
      assert token == "final_page_token_456"

      [%ChannelAccount{} = conv] = conversations

      assert conv.id == "conversation3"
      assert conv.name == "Random Channel"
      assert conv.aadObjectId == "00000000-0000-0000-0000-000000000003"
    end

    test "handles empty conversations list", %{bypass: bypass} do
      team_id = "team123"

      Bypass.expect_once(
        bypass,
        "GET",
        "/v3/teams/#{URI.encode_www_form(team_id)}/conversations",
        fn conn ->
          assert conn |> get_req_header("content-type") |> List.first() == "application/json"
          assert conn |> get_req_header("accept") |> List.first() == "application/json"
          assert conn |> get_req_header("authorization") |> List.first() == "Bearer"

          response_body = %{"conversations" => []}

          resp(conn, 200, Poison.encode!(response_body))
        end
      )

      assert {:ok, result} =
               MsTeams.conversations_list(
                 "http://localhost:#{BypassHelper.port()}",
                 team_id
               )

      assert %{conversations: conversations} = result
      assert conversations == []
    end

    test "handles response without conversations key", %{bypass: bypass} do
      team_id = "team123"

      Bypass.expect_once(
        bypass,
        "GET",
        "/v3/teams/#{URI.encode_www_form(team_id)}/conversations",
        fn conn ->
          assert conn |> get_req_header("content-type") |> List.first() == "application/json"
          assert conn |> get_req_header("accept") |> List.first() == "application/json"
          assert conn |> get_req_header("authorization") |> List.first() == "Bearer"

          response_body = %{}

          resp(conn, 200, Poison.encode!(response_body))
        end
      )

      assert {:ok, result} =
               MsTeams.conversations_list(
                 "http://localhost:#{BypassHelper.port()}",
                 team_id
               )

      assert %{conversations: conversations} = result
      assert conversations == []
    end
  end
end
