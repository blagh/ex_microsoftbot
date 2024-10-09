defmodule ExMicrosoftBot.Analytics.AnalyticsMeta do
  @moduledoc """
    Metadata to be used for analytics events
  """

  @enforce_keys [
    :operation,
    :status,
    :has_retry_after,
    :wait_time
  ]

  defstruct @enforce_keys

  @type t :: %__MODULE__{
          operation: String.t(),
          status: integer(),
          has_retry_after: boolean(),
          wait_time: integer()
        }

  @spec new(map()) :: __MODULE__.t()
  def new(attrs) when is_map(attrs),
    do: struct(__MODULE__, attrs)
end
