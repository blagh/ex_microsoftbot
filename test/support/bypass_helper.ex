defmodule BypassHelper do
  def port, do: Application.fetch_env!(:ex_microsoftbot, Bypass) |> Keyword.fetch!(:port)
end
