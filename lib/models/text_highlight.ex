defmodule ExMicrosoftBot.Models.TextHighlight do
  @moduledoc """
  Represents a text highlight in a message.
  """

  @derive [Poison.Encoder]
  defstruct [
    :text,
    :occurrence
  ]

  @type t :: %__MODULE__{
          text: String.t(),
          occurrence: integer() | nil
        }

  @doc false
  def decoding_map do
    %__MODULE__{}
  end
end
