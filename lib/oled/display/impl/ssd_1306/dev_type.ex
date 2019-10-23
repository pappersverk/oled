defmodule OLED.Display.Impl.SSD1306.DevType do
  @moduledoc false

  @callback init(config :: list()) :: {:ok, term()} | {:error, term()}

  @callback reset(struct()) :: struct() | {:error, term()}
  @callback transfer(struct(), buffer :: binary()) :: struct() | {:error, term()}
  @callback command(struct(), cmd :: integer()) :: struct() | {:error, term()}
end
