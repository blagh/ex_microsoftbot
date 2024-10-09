defmodule ExMicrosoftBot.Client.ConversationsIntegrationTest do
  use ExUnit.Case

  import Plug.Conn, only: [read_body: 1, resp: 3, get_req_header: 2]

  alias ExMicrosoftBot.Models.{
    Activity,
    ChannelAccount,
    ResourceResponse,
    ConversationResourceResponse,
    AttachmentData,
    ConversationParameters
  }

  alias ExMicrosoftBot.Client.Conversations

  @default_error_response %{error: "error"}

  @retryable_responses [
    %{status: 412, response: @default_error_response},
    %{status: 429, response: @default_error_response, headers: [{"Retry-After", "0"}]},
    %{status: 502, response: @default_error_response},
    %{status: 503, response: @default_error_response},
    %{status: 504, response: @default_error_response}
  ]

  @number_of_retries Application.compile_env(:ex_microsoft_bot, :retries_count, 3)

  describe "create_conversation/2" do
    setup do
      bypass = Bypass.open(port: BypassHelper.port())
      {:ok, bypass: bypass}
    end

    test "POSTS the conversation to the given serviceUrl and returns its resource", %{
      bypass: bypass
    } do
      conversation_id = "12345"
      activity_id = "123"
      service_url = "http://localhost:#{BypassHelper.port()}"

      Bypass.expect_once(bypass, "POST", "/v3/conversations", fn conn ->
        conn
        |> assert_common_request_headers()

        {:ok, body, conn} = read_body(conn)

        assert body ==
                 "{\"topicName\":\"topic\",\"members\":[{\"name\":\"user\",\"id\":2}],\"isGroup\":true,\"bot\":{\"name\":\"bot\",\"id\":1},\"activity\":{\"type\":\"message\",\"text\":\"text\"}}"

        resp(
          conn,
          200,
          Jason.encode!(%{id: conversation_id, serviceUrl: service_url, activityId: activity_id})
        )
      end)

      assert Conversations.create_conversation(
               service_url,
               %ConversationParameters{
                 isGroup: true,
                 bot: %ChannelAccount{id: 1, name: "bot"},
                 members: [%ChannelAccount{id: 2, name: "user"}],
                 topicName: "topic",
                 activity: %Activity{type: "message", text: "text"}
               }
             ) ==
               {:ok,
                %ConversationResourceResponse{
                  id: conversation_id,
                  serviceUrl: service_url,
                  activityId: activity_id
                }}
    end

    for response <- @retryable_responses do
      test "Fails after maximum configurable retries for status code : #{inspect(response.status)}",
           %{bypass: bypass} do
        %{status: status, response: response_body} = response = unquote(Macro.escape(response))
        path = "/v3/conversations"
        method = "POST"
        responses = Enum.map(0..@number_of_retries, fn _ -> response end)

        agent_count_pid =
          expect_bot_connector_multiple_responses(bypass, method, path, responses)

        assert Conversations.create_conversation(
                 "http://localhost:#{BypassHelper.port()}",
                 %ConversationParameters{
                   isGroup: true,
                   bot: %ChannelAccount{id: 1, name: "bot"},
                   members: [%ChannelAccount{id: 2, name: "user"}],
                   topicName: "topic",
                   activity: %Activity{type: "message", text: "text"}
                 }
               ) == {:error, status, Jason.encode!(response_body)}

        assert Agent.get(agent_count_pid, fn count -> count end) == 4
      end
    end

    test "Retries and succeeds when a 429 status is followed by a successful response", %{
      bypass: bypass
    } do
      conversation_id = "12345"
      activity_id = "123"
      service_url = "http://localhost:#{BypassHelper.port()}"
      path = "/v3/conversations"
      method = "POST"

      agent_count_pid =
        expect_bot_connector_multiple_responses(bypass, method, path, [
          %{status: 429, response: %{error: "error"}, headers: [{"Retry-After", "0"}]},
          %{
            status: 200,
            response: %{id: conversation_id, activityId: activity_id, serviceUrl: service_url}
          }
        ])

      assert Conversations.create_conversation(
               service_url,
               %ConversationParameters{
                 isGroup: true,
                 bot: %ChannelAccount{id: 1, name: "bot"},
                 members: [%ChannelAccount{id: 2, name: "user"}],
                 topicName: "topic",
                 activity: %Activity{type: "message", text: "text"}
               }
             ) ==
               {:ok,
                %ConversationResourceResponse{
                  id: conversation_id,
                  activityId: activity_id,
                  serviceUrl: service_url
                }}

      assert Agent.get(agent_count_pid, fn count -> count end) == 2
    end
  end

  describe "send_to_conversation/3" do
    setup do
      bypass = Bypass.open(port: BypassHelper.port())
      {:ok, bypass: bypass}
    end

    test "POSTS the activity to the given serviceUrl and returns its resource", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/v3/conversations/42/activities", fn conn ->
        conn
        |> assert_common_request_headers()

        {:ok, body, conn} = read_body(conn)

        assert body ==
                 "{\"type\":\"text\",\"text\":\"ohai\",\"recipient\":{\"name\":\"Jonas\",\"id\":55}}"

        resp(conn, 200, "{\"id\":\"12345\"}")
      end)

      assert Conversations.send_to_conversation(
               "http://localhost:#{BypassHelper.port()}",
               42,
               %Activity{
                 type: "text",
                 recipient: %ChannelAccount{
                   id: 55,
                   name: "Jonas"
                 },
                 text: "ohai"
               }
             ) == {:ok, %ResourceResponse{id: "12345"}}
    end

    for response <- @retryable_responses do
      test "Fails after maximum configurable retries for status code #{inspect(response.status)}",
           %{bypass: bypass} do
        %{status: status, response: response_body} = response = unquote(Macro.escape(response))
        path = "/v3/conversations/42/activities"
        method = "POST"
        responses = Enum.map(0..@number_of_retries, fn _ -> response end)

        agent_count_pid =
          expect_bot_connector_multiple_responses(bypass, method, path, responses)

        assert Conversations.send_to_conversation(
                 "http://localhost:#{BypassHelper.port()}",
                 42,
                 %Activity{
                   type: "text",
                   recipient: %ChannelAccount{
                     id: 55,
                     name: "Jonas"
                   },
                   text: "ohai"
                 }
               ) == {:error, status, Jason.encode!(response_body)}

        assert Agent.get(agent_count_pid, fn count -> count end) == 4
      end
    end

    test "Retries and succeeds when a 429 status is followed by a successful response", %{
      bypass: bypass
    } do
      path = "/v3/conversations/42/activities"
      method = "POST"
      conversation_id = "12345"

      agent_count_pid =
        expect_bot_connector_multiple_responses(bypass, method, path, [
          %{status: 429, response: %{error: "error"}, headers: [{"Retry-After", "0"}]},
          %{
            status: 200,
            response: %{id: conversation_id}
          }
        ])

      assert Conversations.send_to_conversation(
               "http://localhost:#{BypassHelper.port()}",
               42,
               %Activity{
                 type: "text",
                 recipient: %ChannelAccount{
                   id: 55,
                   name: "Jonas"
                 },
                 text: "ohai"
               }
             ) == {:ok, %ResourceResponse{id: conversation_id}}

      assert Agent.get(agent_count_pid, fn count -> count end) == 2
    end
  end

  describe "reply_to_activity/4" do
    setup do
      bypass = Bypass.open(port: BypassHelper.port())
      {:ok, bypass: bypass}
    end

    test "Replies to the activity of a given serviceUrl and returns its resource", %{
      bypass: bypass
    } do
      conversation_id = "42"
      activity_id = "12345"

      Bypass.expect_once(
        bypass,
        "POST",
        "/v3/conversations/#{conversation_id}/activities/#{activity_id}",
        fn conn ->
          assert conn |> get_req_header("content-type") |> List.first() == "application/json"
          assert conn |> get_req_header("accept") |> List.first() == "application/json"
          assert conn |> get_req_header("authorization") |> List.first() == "Bearer"

          {:ok, body, conn} = read_body(conn)

          assert body ==
                   "{\"type\":\"text\",\"text\":\"ohai\",\"recipient\":{\"name\":\"Jonas\",\"id\":55}}"

          resp(conn, 200, "{\"id\":\"12345\"}")
        end
      )

      assert Conversations.reply_to_activity(
               "http://localhost:#{BypassHelper.port()}",
               conversation_id,
               activity_id,
               %Activity{
                 type: "text",
                 recipient: %ChannelAccount{
                   id: 55,
                   name: "Jonas"
                 },
                 text: "ohai"
               }
             ) == {:ok, %ResourceResponse{id: "12345"}}
    end

    for response <- @retryable_responses do
      test "Fails after maximum configurable retries for status code #{inspect(response.status)}",
           %{bypass: bypass} do
        %{status: status, response: response_body} = response = unquote(Macro.escape(response))

        conversation_id = "42"
        activity_id = "12345"
        path = "/v3/conversations/#{conversation_id}/activities/#{activity_id}"
        method = "POST"
        responses = Enum.map(0..@number_of_retries, fn _ -> response end)

        agent_count_pid =
          expect_bot_connector_multiple_responses(bypass, method, path, responses)

        assert Conversations.reply_to_activity(
                 "http://localhost:#{BypassHelper.port()}",
                 conversation_id,
                 activity_id,
                 %Activity{
                   type: "text",
                   recipient: %ChannelAccount{
                     id: 55,
                     name: "Jonas"
                   },
                   text: "ohai"
                 }
               ) == {:error, status, Jason.encode!(response_body)}

        assert Agent.get(agent_count_pid, fn count -> count end) == 4
      end
    end

    test "Retries and succeeds when a 429 status is followed by a successful response", %{
      bypass: bypass
    } do
      conversation_id = "42"
      activity_id = "12345"
      path = "/v3/conversations/#{conversation_id}/activities/#{activity_id}"
      method = "POST"

      agent_count_pid =
        expect_bot_connector_multiple_responses(bypass, method, path, [
          %{status: 429, response: %{error: "error"}, headers: [{"Retry-After", "0"}]},
          %{
            status: 200,
            response: %{id: conversation_id}
          }
        ])

      assert Conversations.reply_to_activity(
               "http://localhost:#{BypassHelper.port()}",
               conversation_id,
               activity_id,
               %Activity{
                 type: "text",
                 recipient: %ChannelAccount{
                   id: 55,
                   name: "Jonas"
                 },
                 text: "ohai"
               }
             ) == {:ok, %ResourceResponse{id: conversation_id}}

      assert Agent.get(agent_count_pid, fn count -> count end) == 2
    end
  end

  describe "get_members/3 for a given activity" do
    setup do
      bypass = Bypass.open(port: BypassHelper.port())
      {:ok, bypass: bypass}
    end

    test "GET members correctly", %{
      bypass: bypass
    } do
      conversation_id = "42"
      activity_id = "12345"

      Bypass.expect_once(
        bypass,
        "GET",
        "/v3/conversations/#{conversation_id}/activities/#{activity_id}/members",
        fn conn ->
          assert conn |> get_req_header("content-type") |> List.first() == "application/json"
          assert conn |> get_req_header("accept") |> List.first() == "application/json"
          assert conn |> get_req_header("authorization") |> List.first() == "Bearer"

          resp(
            conn,
            200,
            "{\"id\":\"id\",\"name\":\"Luis\",\"objectId\":\"objectId\",\"aadObjectId\":\"aadObjectId\",\"givenName\":\"Luis\",\"surname\":\"Aguiar\",\"email\":\"laguiar@pagerduty.com\",\"userPrincipalName\":\"Luis Aguiar\",\"tenantId\":\"tenantId\"}"
          )
        end
      )

      assert Conversations.get_members(
               "http://localhost:#{BypassHelper.port()}",
               conversation_id,
               activity_id
             ) ==
               {:ok,
                %ChannelAccount{
                  id: "id",
                  name: "Luis",
                  aadObjectId: "aadObjectId",
                  objectId: "objectId",
                  givenName: "Luis",
                  surname: "Aguiar",
                  email: "laguiar@pagerduty.com",
                  userPrincipalName: "Luis Aguiar",
                  tenantId: "tenantId"
                }}
    end

    for response <- @retryable_responses do
      test "Fails after maximum configurable retries for status code #{inspect(response.status)}",
           %{bypass: bypass} do
        %{status: status, response: response_body} = response = unquote(Macro.escape(response))

        conversation_id = "42"
        activity_id = "12345"
        path = "/v3/conversations/#{conversation_id}/activities/#{activity_id}/members"
        method = "GET"
        responses = Enum.map(0..@number_of_retries, fn _ -> response end)

        agent_count_pid =
          expect_bot_connector_multiple_responses(bypass, method, path, responses)

        assert Conversations.get_members(
                 "http://localhost:#{BypassHelper.port()}",
                 conversation_id,
                 activity_id
               ) == {:error, status, Jason.encode!(response_body)}

        assert Agent.get(agent_count_pid, fn count -> count end) == 4
      end
    end

    test "Retries and succeeds when a 429 status is followed by a successful response", %{
      bypass: bypass
    } do
      conversation_id = "42"
      activity_id = "12345"
      path = "/v3/conversations/#{conversation_id}/activities/#{activity_id}/members"
      method = "GET"

      agent_count_pid =
        expect_bot_connector_multiple_responses(bypass, method, path, [
          %{status: 429, response: %{error: "error"}, headers: [{"Retry-After", "0"}]},
          %{
            status: 200,
            response: %{
              id: "id",
              name: "Luis",
              aadObjectId: "aadObjectId",
              objectId: "objectId",
              givenName: "Luis",
              surname: "Aguiar",
              email: "laguiar@pagerduty.com",
              userPrincipalName: "Luis Aguiar",
              tenantId: "tenantId"
            }
          }
        ])

      assert Conversations.get_members(
               "http://localhost:#{BypassHelper.port()}",
               conversation_id,
               activity_id
             ) ==
               {:ok,
                %ChannelAccount{
                  id: "id",
                  name: "Luis",
                  aadObjectId: "aadObjectId",
                  objectId: "objectId",
                  givenName: "Luis",
                  surname: "Aguiar",
                  email: "laguiar@pagerduty.com",
                  userPrincipalName: "Luis Aguiar",
                  tenantId: "tenantId"
                }}

      assert Agent.get(agent_count_pid, fn count -> count end) == 2
    end
  end

  describe "get_member/3  without activity" do
    setup do
      bypass = Bypass.open(port: BypassHelper.port())
      {:ok, bypass: bypass}
    end

    test "GET members correctly", %{
      bypass: bypass
    } do
      conversation_id = "42"

      Bypass.expect_once(
        bypass,
        "GET",
        "/v3/conversations/#{conversation_id}/members",
        fn conn ->
          assert conn |> get_req_header("content-type") |> List.first() == "application/json"
          assert conn |> get_req_header("accept") |> List.first() == "application/json"
          assert conn |> get_req_header("authorization") |> List.first() == "Bearer"

          resp(
            conn,
            200,
            "{\"id\":\"id\",\"name\":\"Luis\",\"objectId\":\"objectId\",\"aadObjectId\":\"aadObjectId\",\"givenName\":\"Luis\",\"surname\":\"Aguiar\",\"email\":\"laguiar@pagerduty.com\",\"userPrincipalName\":\"Luis Aguiar\",\"tenantId\":\"tenantId\"}"
          )
        end
      )

      assert Conversations.get_members(
               "http://localhost:#{BypassHelper.port()}",
               conversation_id
             ) ==
               {:ok,
                %ChannelAccount{
                  id: "id",
                  name: "Luis",
                  aadObjectId: "aadObjectId",
                  objectId: "objectId",
                  givenName: "Luis",
                  surname: "Aguiar",
                  email: "laguiar@pagerduty.com",
                  userPrincipalName: "Luis Aguiar",
                  tenantId: "tenantId"
                }}
    end

    for response <- @retryable_responses do
      test "Fails after maximum configurable retries for status code #{inspect(response.status)}",
           %{bypass: bypass} do
        %{status: status, response: response_body} = response = unquote(Macro.escape(response))
        conversation_id = "42"
        path = "/v3/conversations/#{conversation_id}/members"
        method = "GET"
        responses = Enum.map(0..@number_of_retries, fn _ -> response end)

        agent_count_pid =
          expect_bot_connector_multiple_responses(bypass, method, path, responses)

        assert Conversations.get_members(
                 "http://localhost:#{BypassHelper.port()}",
                 conversation_id
               ) == {:error, status, Jason.encode!(response_body)}

        assert Agent.get(agent_count_pid, fn count -> count end) == 4
      end
    end

    test "Retries and succeeds when a 429 status is followed by a successful response", %{
      bypass: bypass
    } do
      conversation_id = "42"
      path = "/v3/conversations/#{conversation_id}/members"
      method = "GET"

      agent_count_pid =
        expect_bot_connector_multiple_responses(bypass, method, path, [
          %{status: 429, response: %{error: "error"}, headers: [{"Retry-After", "0"}]},
          %{
            status: 200,
            response: %{
              id: "id",
              name: "Luis",
              aadObjectId: "aadObjectId",
              objectId: "objectId",
              givenName: "Luis",
              surname: "Aguiar",
              email: "laguiar@pagerduty.com",
              userPrincipalName: "Luis Aguiar",
              tenantId: "tenantId"
            }
          }
        ])

      assert Conversations.get_members(
               "http://localhost:#{BypassHelper.port()}",
               conversation_id
             ) ==
               {:ok,
                %ChannelAccount{
                  id: "id",
                  name: "Luis",
                  aadObjectId: "aadObjectId",
                  objectId: "objectId",
                  givenName: "Luis",
                  surname: "Aguiar",
                  email: "laguiar@pagerduty.com",
                  userPrincipalName: "Luis Aguiar",
                  tenantId: "tenantId"
                }}

      assert Agent.get(agent_count_pid, fn count -> count end) == 2
    end
  end

  describe "get_member/3" do
    setup do
      bypass = Bypass.open(port: BypassHelper.port())
      {:ok, bypass: bypass}
    end

    test "GET ChannelAccount for a given member", %{
      bypass: bypass
    } do
      conversation_id = "42"
      member_id = "12345"

      Bypass.expect_once(
        bypass,
        "GET",
        "/v3/conversations/#{conversation_id}/members/#{member_id}",
        fn conn ->
          assert conn |> get_req_header("content-type") |> List.first() == "application/json"
          assert conn |> get_req_header("accept") |> List.first() == "application/json"
          assert conn |> get_req_header("authorization") |> List.first() == "Bearer"

          resp(
            conn,
            200,
            "{\"id\":\"id\",\"name\":\"Luis\",\"objectId\":\"objectId\",\"aadObjectId\":\"aadObjectId\",\"givenName\":\"Luis\",\"surname\":\"Aguiar\",\"email\":\"laguiar@pagerduty.com\",\"userPrincipalName\":\"Luis Aguiar\",\"tenantId\":\"tenantId\"}"
          )
        end
      )

      assert Conversations.get_member(
               "http://localhost:#{BypassHelper.port()}",
               conversation_id,
               member_id
             ) ==
               {:ok,
                %ChannelAccount{
                  id: "id",
                  name: "Luis",
                  aadObjectId: "aadObjectId",
                  objectId: "objectId",
                  givenName: "Luis",
                  surname: "Aguiar",
                  email: "laguiar@pagerduty.com",
                  userPrincipalName: "Luis Aguiar",
                  tenantId: "tenantId"
                }}
    end

    for response <- @retryable_responses do
      test "Fails after maximum configurable retries for status code #{inspect(response.status)}",
           %{bypass: bypass} do
        %{status: status, response: response_body} = response = unquote(Macro.escape(response))
        conversation_id = "42"
        member_id = "12345"
        path = "/v3/conversations/#{conversation_id}/members/#{member_id}"
        method = "GET"
        responses = Enum.map(0..@number_of_retries, fn _ -> response end)

        agent_count_pid =
          expect_bot_connector_multiple_responses(bypass, method, path, responses)

        assert Conversations.get_member(
                 "http://localhost:#{BypassHelper.port()}",
                 conversation_id,
                 member_id
               ) == {:error, status, Jason.encode!(response_body)}

        assert Agent.get(agent_count_pid, fn count -> count end) == 4
      end
    end

    test "Retries and succeeds when a 429 status is followed by a successful response", %{
      bypass: bypass
    } do
      conversation_id = "42"
      member_id = "12345"
      path = "/v3/conversations/#{conversation_id}/members/#{member_id}"
      method = "GET"

      agent_count_pid =
        expect_bot_connector_multiple_responses(bypass, method, path, [
          %{status: 429, response: %{error: "error"}, headers: [{"Retry-After", "0"}]},
          %{
            status: 200,
            response: %{
              id: "id",
              name: "Luis",
              aadObjectId: "aadObjectId",
              objectId: "objectId",
              givenName: "Luis",
              surname: "Aguiar",
              email: "laguiar@pagerduty.com",
              userPrincipalName: "Luis Aguiar",
              tenantId: "tenantId"
            }
          }
        ])

      assert Conversations.get_member(
               "http://localhost:#{BypassHelper.port()}",
               conversation_id,
               member_id
             ) ==
               {:ok,
                %ChannelAccount{
                  id: "id",
                  name: "Luis",
                  aadObjectId: "aadObjectId",
                  objectId: "objectId",
                  givenName: "Luis",
                  surname: "Aguiar",
                  email: "laguiar@pagerduty.com",
                  userPrincipalName: "Luis Aguiar",
                  tenantId: "tenantId"
                }}

      assert Agent.get(agent_count_pid, fn count -> count end) == 2
    end
  end

  describe "upload_attachment/3" do
    setup do
      bypass = Bypass.open(port: BypassHelper.port())
      {:ok, bypass: bypass}
    end

    test "POSTS the attachment to channels blob with the correct body and headers", %{
      bypass: bypass
    } do
      conversation_id = "42"

      Bypass.expect_once(
        bypass,
        "POST",
        "/v3/conversations/#{conversation_id}/attachments",
        fn conn ->
          assert conn |> get_req_header("content-type") |> List.first() == "application/json"
          assert conn |> get_req_header("accept") |> List.first() == "application/json"
          assert conn |> get_req_header("authorization") |> List.first() == "Bearer"

          {:ok, body, conn} = read_body(conn)

          assert body ==
                   "{\"type\":\"image\",\"thumbnailBase64\":\"base64\",\"originalBase64\":\"base64\",\"name\":\"image.png\"}"

          resp(conn, 200, "{\"id\":\"12345\"}")
        end
      )

      assert Conversations.upload_attachment(
               "http://localhost:#{BypassHelper.port()}",
               conversation_id,
               %AttachmentData{
                 type: "image",
                 name: "image.png",
                 originalBase64: "base64",
                 thumbnailBase64: "base64"
               }
             ) == {:ok, %ResourceResponse{id: "12345"}}
    end

    for response <- @retryable_responses do
      test "Fails after maximum configurable retries for status code #{inspect(response.status)}",
           %{bypass: bypass} do
        %{status: status, response: response_body} = response = unquote(Macro.escape(response))
        conversation_id = "42"
        path = "/v3/conversations/#{conversation_id}/attachments"
        method = "POST"
        responses = Enum.map(0..(@number_of_retries + 1), fn _ -> response end)

        agent_count_pid =
          expect_bot_connector_multiple_responses(bypass, method, path, responses)

        assert Conversations.upload_attachment(
                 "http://localhost:#{BypassHelper.port()}",
                 conversation_id,
                 %AttachmentData{
                   type: "image",
                   name: "image.png",
                   originalBase64: "base64",
                   thumbnailBase64: "base64"
                 }
               ) == {:error, status, Jason.encode!(response_body)}

        assert Agent.get(agent_count_pid, fn count -> count end) == 4
      end
    end

    test "Retries and succeeds when a 429 status is followed by a successful response", %{
      bypass: bypass
    } do
      conversation_id = "42"
      path = "/v3/conversations/#{conversation_id}/attachments"
      method = "POST"

      agent_count_pid =
        expect_bot_connector_multiple_responses(bypass, method, path, [
          %{status: 429, response: %{error: "error"}, headers: [{"Retry-After", "0"}]},
          %{
            status: 200,
            response: %{id: "12345"}
          }
        ])

      assert Conversations.upload_attachment(
               "http://localhost:#{BypassHelper.port()}",
               conversation_id,
               %AttachmentData{
                 type: "image",
                 name: "image.png",
                 originalBase64: "base64",
                 thumbnailBase64: "base64"
               }
             ) == {:ok, %ResourceResponse{id: "12345"}}

      assert Agent.get(agent_count_pid, fn count -> count end) == 2
    end
  end

  describe "update_activity/3" do
    setup do
      bypass = Bypass.open(port: BypassHelper.port())
      {:ok, bypass: bypass}
    end

    test "PUTs the activity to the given serviceUrl and returns its resource", %{bypass: bypass} do
      Bypass.expect_once(bypass, "PUT", "/v3/conversations/42/activities/12345", fn conn ->
        conn
        |> assert_common_request_headers()

        {:ok, body, conn} = read_body(conn)

        assert body ==
                 "{\"type\":\"text\",\"text\":\"ohai\",\"recipient\":{\"name\":\"Jonas\",\"id\":55},\"id\":\"12345\"}"

        resp(conn, 200, "{\"id\":\"12345\"}")
      end)

      assert Conversations.update_activity(
               "http://localhost:#{BypassHelper.port()}",
               42,
               %Activity{
                 id: "12345",
                 type: "text",
                 recipient: %ChannelAccount{
                   id: 55,
                   name: "Jonas"
                 },
                 text: "ohai"
               }
             ) == {:ok, %ResourceResponse{id: "12345"}}
    end

    for response <- @retryable_responses do
      test "Fails after maximum configurable retries for status code #{inspect(response.status)}",
           %{bypass: bypass} do
        %{status: status, response: response_body} = response = unquote(Macro.escape(response))
        conversation_id = "42"
        activity_id = "12345"
        path = "/v3/conversations/#{conversation_id}/activities/#{activity_id}"
        method = "PUT"
        responses = Enum.map(0..@number_of_retries, fn _ -> response end)

        agent_count_pid =
          expect_bot_connector_multiple_responses(bypass, method, path, responses)

        assert Conversations.update_activity(
                 "http://localhost:#{BypassHelper.port()}",
                 conversation_id,
                 %Activity{
                   id: activity_id,
                   type: "text",
                   recipient: %ChannelAccount{
                     id: 55,
                     name: "Jonas"
                   },
                   text: "ohai"
                 }
               ) == {:error, status, Jason.encode!(response_body)}

        assert Agent.get(agent_count_pid, fn count -> count end) == 4
      end
    end

    test "Retries and succeeds when a 429 status is followed by a successful response", %{
      bypass: bypass
    } do
      conversation_id = "42"
      activity_id = "12345"
      path = "/v3/conversations/#{conversation_id}/activities/#{activity_id}"
      method = "PUT"

      agent_count_pid =
        expect_bot_connector_multiple_responses(bypass, method, path, [
          %{status: 429, response: %{error: "error"}, headers: [{"Retry-After", "0"}]},
          %{
            status: 200,
            response: %{id: "12345"}
          }
        ])

      assert Conversations.update_activity(
               "http://localhost:#{BypassHelper.port()}",
               conversation_id,
               %Activity{
                 id: activity_id,
                 type: "text",
                 recipient: %ChannelAccount{
                   id: 55,
                   name: "Jonas"
                 },
                 text: "ohai"
               }
             ) == {:ok, %ResourceResponse{id: activity_id}}

      assert Agent.get(agent_count_pid, fn count -> count end) == 2
    end
  end

  describe "delete_activity/3" do
    setup do
      bypass = Bypass.open(port: BypassHelper.port())
      {:ok, bypass: bypass}
    end

    test "DELETEs the activity given serviceUrl", %{bypass: bypass} do
      Bypass.expect_once(bypass, "DELETE", "/v3/conversations/42/activities/12345", fn conn ->
        conn
        |> assert_common_request_headers()

        assert {:ok, "", conn} = read_body(conn)

        resp(conn, 200, "")
      end)

      assert Conversations.delete_activity(
               "http://localhost:#{BypassHelper.port()}",
               42,
               %Activity{
                 id: "12345",
                 type: "text",
                 recipient: %ChannelAccount{
                   id: 55,
                   name: "Jonas"
                 },
                 text: "ohai"
               }
             ) == {:ok, ""}
    end

    for response <- @retryable_responses do
      test "Fails after maximum configurable retries for status code #{inspect(response.status)}",
           %{bypass: bypass} do
        %{status: status, response: response_body} = response = unquote(Macro.escape(response))

        conversation_id = "42"
        activity_id = "12345"
        path = "/v3/conversations/#{conversation_id}/activities/#{activity_id}"
        method = "DELETE"
        responses = Enum.map(0..@number_of_retries, fn _ -> response end)

        agent_count_pid =
          expect_bot_connector_multiple_responses(bypass, method, path, responses)

        assert Conversations.delete_activity(
                 "http://localhost:#{BypassHelper.port()}",
                 conversation_id,
                 %Activity{
                   id: activity_id,
                   type: "text",
                   recipient: %ChannelAccount{
                     id: 55,
                     name: "Jonas"
                   },
                   text: "ohai"
                 }
               ) == {:error, status, Jason.encode!(response_body)}

        assert Agent.get(agent_count_pid, fn count -> count end) == 4
      end
    end

    test "Retries and succeeds when a 429 status is followed by a successful response", %{
      bypass: bypass
    } do
      conversation_id = "42"
      activity_id = "12345"
      path = "/v3/conversations/#{conversation_id}/activities/#{activity_id}"
      method = "DELETE"

      agent_count_pid =
        expect_bot_connector_multiple_responses(bypass, method, path, [
          %{status: 429, response: %{error: "error"}, headers: [{"Retry-After", "0"}]},
          %{
            status: 200,
            response: ""
          }
        ])

      assert Conversations.delete_activity(
               "http://localhost:#{BypassHelper.port()}",
               conversation_id,
               %Activity{
                 id: activity_id,
                 type: "text",
                 recipient: %ChannelAccount{
                   id: 55,
                   name: "Jonas"
                 },
                 text: "ohai"
               }
             ) == {:ok, ""}

      assert Agent.get(agent_count_pid, fn count -> count end) == 2
    end
  end

  defp expect_bot_connector_multiple_responses(
         bypass,
         method,
         path,
         responses
       ) do
    # Start an agent to keep track of the call count
    {:ok, call_count} = Agent.start_link(fn -> 0 end)

    # Define the expectation
    Bypass.expect(bypass, method, path, fn conn ->
      # Get the current call count
      current_count = Agent.get(call_count, fn count -> count end)

      # Increment the call count
      Agent.update(call_count, fn count -> count + 1 end)

      # Handle response for the current call count
      conn
      |> handle_response(Enum.at(responses, current_count))
    end)

    call_count
  end

  defp handle_response(conn, %{status: status, response: response, headers: headers}) do
    conn
    |> Plug.Conn.merge_resp_headers(headers)
    |> Plug.Conn.resp(status, handle_response_encoding(response))
  end

  defp handle_response(conn, %{status: status, response: response}) do
    conn
    |> Plug.Conn.resp(status, handle_response_encoding(response))
  end

  defp handle_response_encoding(response) when is_map(response), do: Jason.encode!(response)

  defp handle_response_encoding(response) when is_binary(response), do: response

  defp assert_common_request_headers(conn) do
    assert conn |> get_req_header("content-type") |> List.first() == "application/json"
    assert conn |> get_req_header("accept") |> List.first() == "application/json"
    assert conn |> get_req_header("authorization") |> List.first() == "Bearer"
  end
end
