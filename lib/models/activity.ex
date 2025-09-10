defmodule ExMicrosoftBot.Models.Activity do
  @moduledoc """
  Microsoft bot attachment structure for the activity sent to the conversation
  """

  @derive [Poison.Encoder]
  defstruct [
    :type,
    :id,
    :timestamp,
    :serviceUrl,
    :channelId,
    :from,
    :conversation,
    :recipient,
    :relatesTo,
    :textFormat,
    :attachmentLayout,
    :membersAdded,
    :membersRemoved,
    :reactionsAdded,
    :reactionsRemoved,
    :topicName,
    :historyDisclosed,
    :locale,
    :localTimestamp,
    :localTimezone,
    :text,
    :speak,
    :summary,
    :textHighlights,
    :attachments,
    :entities,
    :semanticAction,
    :suggestedActions,
    :channelData,
    :action,
    :replyToId,
    :code,
    :inputHint,
    :value,
    :valueType,
    :properties,
    :deliveryMode,
    :expiration,
    :importance,
    :label,
    :listenFor,
    :callerId,
    :name
  ]

  @type json_base_value :: String.t() | number | boolean
  @type json_object ::
          json_base_value | [json_base_value] | %{optional(String.t()) => json_object}
  @type t :: %ExMicrosoftBot.Models.Activity{
          type: String.t(),
          id: String.t(),
          timestamp: String.t(),
          serviceUrl: String.t(),
          channelId: String.t(),
          from: ExMicrosoftBot.Models.ChannelAccount.t(),
          conversation: ExMicrosoftBot.Models.ConversationAccount.t(),
          recipient: ExMicrosoftBot.Models.ChannelAccount.t(),
          relatesTo: ExMicrosoftBot.Models.ConversationReference.t(),
          textFormat: String.t(),
          attachmentLayout: String.t(),
          membersAdded: [ExMicrosoftBot.Models.ChannelAccount.t()],
          membersRemoved: [ExMicrosoftBot.Models.ChannelAccount.t()],
          reactionsAdded: [ExMicrosoftbot.Models.Reaction.t()],
          reactionsRemoved: [ExMicrosoftbot.Models.Reaction.t()],
          topicName: String.t(),
          historyDisclosed: boolean,
          locale: String.t(),
          localTimestamp: String.t(),
          localTimezone: String.t(),
          text: String.t(),
          speak: String.t(),
          summary: String.t(),
          textHighlights: [ExMicrosoftBot.Models.TextHighlight.t()],
          attachments: [ExMicrosoftBot.Models.Attachment.t()],
          entities: [ExMicrosoftBot.Models.Entity.t()],
          semanticAction: ExMicrosoftBot.Models.SemanticAction.t(),
          suggestedActions: [ExMicrosoftBot.Models.SuggestedAction.t()],
          channelData: map,
          action: String.t(),
          replyToId: String.t(),
          code: String.t(),
          inputHint: String.t(),
          value: json_object,
          valueType: String.t(),
          properties: json_object,
          # 'normal', 'notification', or 'expectReplies'
          deliveryMode: String.t(),
          expiration: String.t(),
          # 'normal', 'low', or 'high'
          importance: String.t(),
          label: String.t(),
          listenFor: [String.t()],
          callerId: String.t(),
          name: String.t()
        }

  @doc """
  Decode a map into `ExMicrosoftBot.Models.Activity`
  """
  @spec parse(map) :: {:ok, ExMicrosoftBot.Models.Activity.t()}
  def parse(param) when is_map(param) do
    {:ok, Poison.Decode.transform(param, %{as: decoding_map()})}
  end

  @spec parse(String.t()) :: ExMicrosoftBot.Models.Activity.t()
  def parse(param) when is_binary(param) do
    Poison.decode!(param, as: decoding_map())
  end

  @doc false
  def decoding_map() do
    %ExMicrosoftBot.Models.Activity{
      from: ExMicrosoftBot.Models.ChannelAccount.decoding_map(),
      conversation: ExMicrosoftBot.Models.ConversationAccount.decoding_map(),
      relatesTo: ExMicrosoftBot.Models.ConversationReference.decoding_map(),
      recipient: ExMicrosoftBot.Models.ChannelAccount.decoding_map(),
      membersAdded: [ExMicrosoftBot.Models.ChannelAccount.decoding_map()],
      membersRemoved: [ExMicrosoftBot.Models.ChannelAccount.decoding_map()],
      reactionsAdded: [ExMicrosoftBot.Models.Reaction.decoding_map()],
      reactionsRemoved: [ExMicrosoftBot.Models.Reaction.decoding_map()],
      attachments: [ExMicrosoftBot.Models.Attachment.decoding_map()],
      entities: [ExMicrosoftBot.Models.Entity.decoding_map()],
      suggestedActions: [ExMicrosoftBot.Models.SuggestedAction.decoding_map()],
      textHighlights: [ExMicrosoftBot.Models.TextHighlight.decoding_map()],
      semanticAction: ExMicrosoftBot.Models.SemanticAction.decoding_map(),
      channelData: %{},
      properties: %{}
    }
  end
end
