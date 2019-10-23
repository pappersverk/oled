defmodule OLED.Display.Helper do
  @moduledoc false

  def validate_config(required, config) do
    Enum.reduce_while(required, nil, fn key, _ ->
      if Keyword.has_key?(config, key) do
        {:cont, :ok}
      else
        {:error, {:missed_config, key}}
      end
    end)
  end
end
