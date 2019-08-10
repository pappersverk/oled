defmodule OLED.Display.Impl do
  @moduledoc false

  alias OLED.Display.Impl

  @impl_list [
    ssd1306: Impl.SSD1306
  ]

  def init(config) do
    driver = config[:driver]

    with {:ok, impl} <- get_impl(driver),
         {:ok, state} <- impl.initialize(config) do
      {:ok, {impl, state}}
    else
      {:error, error} ->
        {:stop, error}
    end
  end

  defp get_impl(driver) do
    case @impl_list[driver] do
      nil ->
        {:error, :unknown_driver}

      impl ->
        {:ok, impl}
    end
  end
end
