defmodule OLED.DummyDev do
  @behaviour OLED.Display.Impl.SSD1306.DevType

  defstruct []

  @impl true
  def init(config) do
    send(self(), {:init, config})
    %__MODULE__{}
  end

  @impl true
  def reset(%__MODULE__{} = state) do
    send(self(), :reset)
    state
  end

  @impl true
  def transfer(%__MODULE__{} = state, buffer) do
    send(self(), {:transfer, buffer})
    state
  end

  @impl true
  def command(%__MODULE__{} = state, cmd) do
    send(self(), {:command, cmd})
    state
  end
end
