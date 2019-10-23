defmodule OLED.Display.Impl.SSD1306.SPI do
  @moduledoc false

  alias Circuits.{GPIO, SPI}
  import OLED.Display.Helper, only: [validate_config: 2]

  @behaviour OLED.Display.Impl.SSD1306.DevType

  @spi_speed 8_000_000

  @required_config [
    :device,
    :dc_pin,
    :rst_pin
  ]

  defstruct device: nil, rst: nil, dc: nil

  @type t :: %__MODULE__{
          device: SPI.spi_bus(),
          dc: integer(),
          rst: integer()
        }

  @impl true
  def init(config) do
    with :ok <- validate_config(@required_config, config),
         {:ok, rst} <- GPIO.open(config[:rst_pin], :output),
         {:ok, dc} <- GPIO.open(config[:dc_pin], :output),
         {:ok, device} <- SPI.open(config[:device], speed_hz: @spi_speed) do
      {:ok, %__MODULE__{device: device, rst: rst, dc: dc}}
    end
  end

  def init(_, _),
    do: {:error, :invalid_args}

  @impl true
  def reset(%__MODULE__{rst: rst} = state) do
    with :ok <- GPIO.write(rst, 1),
         _ <- :timer.sleep(5),
         :ok <- GPIO.write(rst, 0),
         _ <- :timer.sleep(10),
         :ok <- GPIO.write(rst, 1),
         _ <- :timer.sleep(100) do
      state
    else
      _ ->
        {:error, :display_reset}
    end
  end

  def reset(error),
    do: error

  @impl true
  def transfer(%__MODULE__{device: device, dc: dc} = state, buffer) do
    with :ok <- GPIO.write(dc, 1),
         {:ok, _} <- SPI.transfer(device, buffer) do
      state
    end
  end

  def transfer(error, _buffer),
    do: error

  @impl true
  def command(%__MODULE__{device: device, dc: dc} = state, cmd) when is_integer(cmd) do
    with :ok <- GPIO.write(dc, 0),
         {:ok, _} <- SPI.transfer(device, <<cmd>>) do
      state
    else
      error ->
        {:error, {:cmd, cmd, error}}
    end
  end
end
