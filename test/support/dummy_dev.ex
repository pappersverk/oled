defmodule OLED.DummyDev do
  @behaviour OLED.Display.Impl.SSD1306.DevType

  defstruct []

  @impl true
  def init(config) do
    send(self(), {:init, config})
    %__MODULE__{}
  end

  @impl true
  def reset(%__MODULE__{}) do
    send(self(), :reset)
    %__MODULE__{}
  end

  @impl true
  def transfer(%__MODULE__{}, buffer) do
    send(self(), {:transfer, buffer})
    %__MODULE__{}
  end

  @impl true
  def command(%__MODULE__{}, cmd) do
    send(self(), {:command, cmd})
    %__MODULE__{}
  end
end
