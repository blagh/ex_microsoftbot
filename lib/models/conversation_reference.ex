defmodule ExMicrosoftBot.Models.ConversationReference do
  @moduledoc """
  Represents a reference to another conversation within a channel.
  """

  @derive [Poison.Encoder]
  defstruct [
    :activityId,
    :agent,
    :channelId,
    :conversation,
    :locale,
    :serviceUrl,
    :user
  ]

  @type t :: %__MODULE__{
          activityId: String.t(),
          agent: ExMicrosoftBot.Models.ChannelAccount.t(),
          channelId: String.t(),
          conversation: ExMicrosoftBot.Models.ConversationAccount.t(),
          locale: String.t(),
          serviceUrl: String.t(),
          user: ExMicrosoftBot.Models.ChannelAccount.t()
        }

  @doc false
  def decoding_map() do
    %__MODULE__{
      agent: ExMicrosoftBot.Models.ChannelAccount.decoding_map(),
      conversation: ExMicrosoftBot.Models.ConversationAccount.decoding_map(),
      user: ExMicrosoftBot.Models.ChannelAccount.decoding_map()
    }
  end
end
