defmodule ExMicrosoftBot.Models.ActivityTest do
  use ExUnit.Case, async: true

  alias ExMicrosoftBot.Models.Activity

  describe ".parse/1" do
    test "parses a fully populated activity model" do
      {:ok,
       %Activity{
         type: type,
         id: id,
         timestamp: timestamp,
         serviceUrl: serviceUrl,
         channelId: channelId,
         from: from,
         conversation: conversation,
         relatesTo: relatesTo,
         recipient: recipient,
         textFormat: textFormat,
         attachmentLayout: attachmentLayout,
         membersAdded: membersAdded,
         membersRemoved: membersRemoved,
         reactionsAdded: reactionsAdded,
         reactionsRemoved: reactionsRemoved,
         topicName: topicName,
         historyDisclosed: historyDisclosed,
         locale: locale,
         localTimestamp: localTimestamp,
         localTimezone: localTimezone,
         text: text,
         speak: speak,
         summary: summary,
         attachments: attachments,
         entities: entities,
         textHighlights: textHighlights,
         suggestedActions: suggestedActions,
         channelData: channelData,
         action: action,
         value: value,
         valueType: valueType,
         properties: properties,
         semanticAction: semanticAction,
         deliveryMode: deliveryMode,
         expiration: expiration,
         importance: importance,
         label: label,
         inputHint: inputHint,
         listenFor: listenFor,
         callerId: callerId,
         code: code,
         name: name,
         replyToId: replyToId
       }} =
        Activity.parse(%{
          "type" => "message",
          "id" => "1556500798576",
          "timestamp" => "2019-04-29T01:19:58.647Z",
          "serviceUrl" => "https://smba.trafficmanager.net/emea/",
          "channelId" => "msteams",
          "from" => %{"id" => "some:id", "name" => "Some Name"},
          "conversation" => %{
            "isGroup" => true,
            "id" => "another:id",
            "name" => "Things",
            "conversationType" => "channel"
          },
          "relatesTo" => %{
            "activityId" => "activity:id",
            "agent" => %{"id" => "agent:id", "name" => "Agent Name"},
            "channelId" => "msteams",
            "conversation" => %{
              "isGroup" => false,
              "id" => "conv:id",
              "name" => "Another One",
              "conversationType" => "personal"
            },
            "locale" => "en-US",
            "serviceUrl" => "https://smba.trafficmanager.net/emea/",
            "user" => %{"id" => "user:id", "name" => "User Name"}
          },
          "recipient" => %{"id" => "someother:id", "name" => "Some Other Name"},
          "textFormat" => "plain",
          "attachmentLayout" => "flat",
          "membersAdded" => [%{"id" => "someother:id", "name" => "Some Other Name"}],
          "membersRemoved" => [%{"id" => "some:id", "name" => "Some Name"}],
          "reactionsAdded" => [%{"type" => "heart"}],
          "reactionsRemoved" => [%{"type" => "heart"}],
          "topicName" => "Potatoes",
          "historyDisclosed" => false,
          "locale" => "en-US",
          "text" => "Hello!",
          "speak" => "This is Microsoft Sam",
          "summary" => "Sam speaks hello",
          "attachments" => [
            %{
              "contentType" => "image/png",
              "contentUrl" => "https://some.site/image.png",
              "name" => "A great picture",
              "thumbnailUrl" => "https://some.site/image-tiny.png"
            }
          ],
          "entities" => [
            %{
              "mentioned" => %{
                "id" => "28:f2ab3d75-7b12-4ceb-a730-1d45e461c9bf",
                "name" => "Bot"
              },
              "text" => "<at>Bot</at>",
              "type" => "mention"
            },
            %{
              "mentioned" => %{
                "id" =>
                  "29:1LnoI0QitUZxiOvOm1QYzuVuUGrpUiTF79TMwkeS1MftPFLKxAc-wpZ_14rQRGX30LShBpgiPvKn-MLaIBycwvg",
                "name" => "User Name"
              },
              "text" => "<at>User Name</at>",
              "type" => "mention"
            }
          ],
          "textHighlights" => [%{"text" => "highlighted", "occurrence" => 5}],
          "channelData" => %{
            "tenant" => %{
              "id" => "234567890"
            }
          },
          "action" => "engage",
          "inputHint" => "hint hint",
          "code" => "42",
          "replyToId" => "123234345",
          "value" => %{
            "some_text" => "halp",
            "some_number" => 42
          },
          "valueType" => "Some.ValueType",
          "properties" => %{},
          "suggestedActions" => [
            %{
              "actions" => [
                %{
                  "type" => "imBack",
                  "title" => "Do The Thing",
                  "value" => "Value 1"
                }
              ],
              "to" => "Zhu Li"
            }
          ],
          "semanticAction" => %{
            "id" => "action:id",
            "entities" => [            %{
              "mentioned" => %{
                "id" => "28:f2ab3d75-7b12-4ceb-a730-1d45e461c9bf",
                "name" => "Bot"
              },
              "text" => "<at>Bot</at>",
              "type" => "mention"
            }],
            "state" => "starting"
          },
          "deliveryMode" => "normal",
          "expiration" => "2024-12-31T23:59:59.999Z",
          "importance" => "normal",
          "label" => "label",
          "listenFor" => ["listen for this"],
          "callerId" => "caller:id",
          "name" => "Activity Name",
          "localTimestamp" => "2019-04-29T02:19:58.647+01:00",
          "localTimezone" => "Europe/Lisbon"
        })

      assert type == "message"
      assert id == "1556500798576"
      assert timestamp == "2019-04-29T01:19:58.647Z"
      assert serviceUrl == "https://smba.trafficmanager.net/emea/"
      assert channelId == "msteams"

      assert from == %ExMicrosoftBot.Models.ChannelAccount{
               id: "some:id",
               name: "Some Name"
             }

      assert conversation == %ExMicrosoftBot.Models.ConversationAccount{
               isGroup: true,
               id: "another:id",
               name: "Things",
               conversationType: "channel"
             }

      assert relatesTo == %ExMicrosoftBot.Models.ConversationReference{
               activityId: "activity:id",
               agent: %ExMicrosoftBot.Models.ChannelAccount{
                 id: "agent:id",
                 name: "Agent Name"
               },
               channelId: "msteams",
               conversation: %ExMicrosoftBot.Models.ConversationAccount{
                 isGroup: false,
                 id: "conv:id",
                 name: "Another One",
                 conversationType: "personal"
               },
               locale: "en-US",
               serviceUrl: "https://smba.trafficmanager.net/emea/",
               user: %ExMicrosoftBot.Models.ChannelAccount{
                 id: "user:id",
                 name: "User Name"
               }
             }

      assert recipient == %ExMicrosoftBot.Models.ChannelAccount{
               id: "someother:id",
               name: "Some Other Name"
             }

      assert textFormat == "plain"
      assert attachmentLayout == "flat"

      assert membersAdded == [
               %ExMicrosoftBot.Models.ChannelAccount{
                 id: "someother:id",
                 name: "Some Other Name"
               }
             ]

      assert membersRemoved == [
               %ExMicrosoftBot.Models.ChannelAccount{
                 id: "some:id",
                 name: "Some Name"
               }
             ]

      assert reactionsAdded == [
               %ExMicrosoftBot.Models.Reaction{
                 type: "heart"
               }
             ]

      assert reactionsRemoved == [
               %ExMicrosoftBot.Models.Reaction{
                 type: "heart"
               }
             ]

      assert topicName == "Potatoes"
      assert historyDisclosed == false
      assert locale == "en-US"
      assert localTimestamp == "2019-04-29T02:19:58.647+01:00"
      assert localTimezone == "Europe/Lisbon"
      assert text == "Hello!"
      assert speak == "This is Microsoft Sam"
      assert summary == "Sam speaks hello"

      assert attachments == [
               %ExMicrosoftBot.Models.Attachment{
                 contentType: "image/png",
                 contentUrl: "https://some.site/image.png",
                 name: "A great picture",
                 thumbnailUrl: "https://some.site/image-tiny.png"
               }
             ]

      assert entities == [
               %ExMicrosoftBot.Models.Entity{
                 type: "mention",
                 text: "<at>Bot</at>",
                 mentioned: %ExMicrosoftBot.Models.Entity.Mentioned{
                   id: "28:f2ab3d75-7b12-4ceb-a730-1d45e461c9bf",
                   name: "Bot"
                 }
               },
               %ExMicrosoftBot.Models.Entity{
                 type: "mention",
                 text: "<at>User Name</at>",
                 mentioned: %ExMicrosoftBot.Models.Entity.Mentioned{
                   id:
                     "29:1LnoI0QitUZxiOvOm1QYzuVuUGrpUiTF79TMwkeS1MftPFLKxAc-wpZ_14rQRGX30LShBpgiPvKn-MLaIBycwvg",
                   name: "User Name"
                 }
               }
             ]

      assert textHighlights == [
               %ExMicrosoftBot.Models.TextHighlight{
                 text: "highlighted",
                 occurrence: 5
               }
             ]

      assert suggestedActions == [
               %ExMicrosoftBot.Models.SuggestedAction{
                 actions: [
                   %ExMicrosoftBot.Models.CardAction{
                     type: "imBack",
                     title: "Do The Thing",
                     value: "Value 1"
                   }
                 ],
                 to: "Zhu Li"
               }
             ]

      assert semanticAction == %ExMicrosoftBot.Models.SemanticAction{
               id: "action:id",
               entities: [
                 %ExMicrosoftBot.Models.Entity{
                  type: "mention",
                  text: "<at>Bot</at>",
                  mentioned: %ExMicrosoftBot.Models.Entity.Mentioned{
                    id: "28:f2ab3d75-7b12-4ceb-a730-1d45e461c9bf",
                    name: "Bot"
                  }
               },
               ],
               state: "starting"
             }

      assert channelData == %{
               "tenant" => %{
                 "id" => "234567890"
               }
             }

      assert action == "engage"
      assert inputHint == "hint hint"
      assert code == "42"
      assert replyToId == "123234345"

      assert value == %{
               "some_text" => "halp",
               "some_number" => 42
             }

      assert valueType == "Some.ValueType"
      assert properties == nil
      assert deliveryMode == "normal"
      assert expiration == "2024-12-31T23:59:59.999Z"
      assert importance == "normal"
      assert label == "label"
      assert listenFor == ["listen for this"]
      assert callerId == "caller:id"
      assert name == "Activity Name"
    end

    test "handles empty payload" do
      {:ok, %Activity{}} = Activity.parse(%{})
    end
  end
end
