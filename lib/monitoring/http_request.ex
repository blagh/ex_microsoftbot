defmodule ExMicrosoftBot.Monitoring.HttpRequest do
  @moduledoc """
  Same module as the Toolbox.Monitoring.HttpRequest: https://github.com/PagerDuty/collabops-toolbox/blob/main/lib/toolbox/monitoring/http_request.ex

  ...

  The data structure includes the following fields:

  - `:operation` - A string that describes the operation related to the HTTP request.
  - `:method` - An atom that represents the HTTP method. It can be `:get`, `:post`, `:put`, or `:delete`.
  - `:parse_body_func` - A function that parses the body of the HTTP response.
  - `:body_condition_func` - A function that checks a certain condition on the response of the HTTP request.

  The `:body_condition_func` is expected to be a function that takes an integer and a map (the status code and the deserialization of the response body) as arguments and returns either `:success` or `:failure`.

  To use this module, you need to create a new struct by passing a map to the `new/1` function. The map should include `:operation`, `:method`, and may optionally include `:parse_body_func` and `:body_condition_func`.

  Here's an example:

      iex> attrs = %{operation: "/api/data", method: :get}
      iex> ExMicrosoftBot.Monitoring.HttpRequest.new(attrs)
      %ExMicrosoftBot.Monitoring.HttpRequest{operation: "/api/data", method: :get, parse_body_func: nil, body_condition_func: nil}

    If you want to include a `:body_condition_func`, you can do so by defining an anonymous function. This function should take an integer (the status code) and a map (the decoded JSON response body) as arguments and return either `:success` or `:failure`.

  Here's an example:

      iex> condition_checker_func = fn status, decoded_json -> if(status == 200 and Map.get(decoded_json, "ok"), do: :success, else: :failure) end
      iex> attrs = %{operation: "/api/data", method: :get, parse_body_func: fn body -> Jason.decode!(body) end, body_condition_func: condition_checker_func}
      iex> ExMicrosoftBot.Monitoring.HttpRequest.new(attrs)
      %ExMicrosoftBot.Monitoring.HttpRequest{operation: "GET /api/data", parse_body_func: func, body_condition_func: func}
  """

  @enforce_keys [:operation, :method]

  defstruct operation: nil,
            method: nil,
            parse_body_func: nil,
            body_condition_func: nil

  @type t :: %__MODULE__{
          operation: String.t(),
          method: :get | :post | :put | :delete,
          parse_body_func: (String.t() -> map()),
          body_condition_func: (integer, map -> :success | :failure)
        }

  @doc """
  Creates a new HttpRequest struct.

  ## Params

  - `attrs`: A map that includes `:operation`, `:method`, `parse_body_func` and may optionally include `:body_condition_func`.

  ## Examples

      iex> attrs = %{operation: "/api/data", method: :get, parse_body_func: fn body -> Jason.decode!(body) end}
      iex> ExMicrosoftBot.Monitoring.HttpRequest.new(attrs)
      %ExMicrosoftBot.Monitoring.HttpRequest{operation: "GET /api/data", method: :get, parse_body_func: func, body_condition_func: nil}
  """
  @spec new(map() | keyword()) :: t
  def new(attrs) when is_map(attrs),
    do:
      struct!(
        __MODULE__,
        Map.merge(%{parse_body_func: &Jason.decode/1}, attrs)
      )

  def new(attrs) when is_list(attrs),
    do:
      struct!(
        __MODULE__,
        Keyword.merge([parse_body_func: &Jason.decode/1], attrs)
      )
end
