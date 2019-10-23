defmodule OLED.Display.Impl.SSD1306.I2C do
  @moduledoc false

  alias Circuits.I2C
  import OLED.Display.Helper, only: [validate_config: 2]
  @behaviour OLED.Display.Impl.SSD1306.DevType

  @required_config [
    :device,
    :address
  ]

  defstruct device: nil, address: nil

  @type t :: %__MODULE__{
          device: I2C.bus(),
          address: integer()
        }

  @impl true
  def init(config) do
    with :ok <- validate_config(@required_config, config),
         {:address, true} <- {:address, is_integer(config[:address])},
         {:ok, device} <- I2C.open(config[:device]) do
      {:ok, %__MODULE__{device: device, address: config[:address]}}
    else
      {:address, _} ->
        {:error, :invalid_address}

      error ->
        error
    end
  end

  def init(_, _),
    do: {:error, :invalid_args}

  @impl true
  def reset(%__MODULE__{} = state),
    do: state

  def reset(error),
    do: error

  @impl true
  def transfer(%__MODULE__{device: device, address: addr} = state, buffer) do
    with :ok <- I2C.write(device, addr, [0x40, buffer]) do
      state
    end
  end

  def transfer(error, _buffer),
    do: error

  @impl true
  def command(%__MODULE__{device: device, address: addr} = state, cmd) when is_integer(cmd) do
    with :ok <- I2C.write(device, addr, <<0x00, cmd>>) do
      state
    else
      error ->
        {:error, {:cmd, cmd, error}}
    end
  end
end
