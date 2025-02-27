defmodule ExMicrosoftBot.Models.Entity do
  @moduledoc """
  Microsoft bot entity structure
  """

  @derive [Poison.Encoder]
  defstruct [:type, :text, :mentioned, :country, :locale, :timezone]

  @type t :: %__MODULE__{
          type: String.t(),
          text: String.t(),
          country: String.t(),
          locale: String.t(),
          timezone: String.t(),
          mentioned: __MODULE__.Mentioned.t()
        }

  defmodule __MODULE__.Mentioned do
    @derive [Poison.Encoder]
    defstruct [:id, :name]

    @type t :: %__MODULE__{
            id: String.t(),
            name: String.t()
          }
    def decoding_map(), do: %__MODULE__{}
  end

  @doc """
  Decoding map for the entity
  """
  def decoding_map() do
    %__MODULE__{
      mentioned: %__MODULE__.Mentioned{}
    }
  end
end
