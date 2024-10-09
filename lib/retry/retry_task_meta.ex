defmodule ExMicrosoftBot.Retry.RetryTaskMeta do
  @moduledoc """
    Metadata to be used for the retried tasks
  """

  @enforce_keys [
    :current_retry,
    :max_retries,
    :wait_time
  ]

  defstruct @enforce_keys

  @type t :: %__MODULE__{
          current_retry: integer(),
          max_retries: integer(),
          wait_time: integer()
        }

  @spec new(map()) :: __MODULE__.t()
  def new(attrs) when is_map(attrs),
    do: struct(__MODULE__, attrs)
end
