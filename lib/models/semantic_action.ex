defmodule ExMicrosoftBot.Models.SemanticAction do
  @moduledoc """
  Represents a reference to a programmatic action.
  """

  @derive [Poison.Encoder]
  defstruct [
    :entities,
    :id,
    :state
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          entities: [ExMicrosoftBot.Models.Entity.t()],
          # starting, continuing, or done
          state: String.t()
        }

  @doc false
  def decoding_map do
    %__MODULE__{
      entities: [ExMicrosoftBot.Models.Entity.decoding_map()]
    }
  end
end
