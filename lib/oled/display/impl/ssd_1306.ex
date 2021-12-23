defmodule OLED.Display.Impl.SSD1306 do
  @moduledoc false

  alias OLED.Display.Impl.SSD1306.{
    Draw,
    I2C,
    SPI
  }

  use Bitwise, only_operators: true
  import OLED.Display.Helper, only: [validate_config: 2]

  @ssd1306_setcontrast 0x81
  @ssd1306_displayallon_resume 0xA4
  # @ssd1306_displayallon 0xA5
  @ssd1306_normaldisplay 0xA6
  # @ssd1306_invertdisplay 0xA7
  @ssd1306_displayon 0xAF
  @ssd1306_displayoff 0xAE
  @ssd1306_setdisplayoffset 0xD3
  @ssd1306_setcompins 0xDA
  @ssd1306_setvcomdetect 0xDB
  @ssd1306_setdisplayclockdiv 0xD5
  @ssd1306_setprecharge 0xD9
  @ssd1306_setmultiplex 0xA8
  # @ssd1306_setlowcolumn 0x00
  # @ssd1306_sethighcolumn 0x10
  @ssd1306_setstartline 0x40
  @ssd1306_memorymode 0x20
  @ssd1306_columnaddr 0x21
  @ssd1306_pageaddr 0x22
  # @ssd1306_comscaninc 0xC0
  @ssd1306_comscandec 0xC8
  @ssd1306_segremap 0xA0
  @ssd1306_chargepump 0x8D
  @ssd1306_deactivate_scroll 0x2E
  # @ssd1306_activate_scroll 0x2F

  @default_config [
    width: 128,
    height: 64,
    external_vcc: false
  ]

  @required_config [
    :type
  ]

  @display_opts [
    memory_mode: :horizontal
  ]

  defstruct width: nil,
            height: nil,
            buffer: nil,
            dev: nil,
            external_vcc: nil

  defdelegate put_pixel(state, x, y, opts), to: Draw
  defdelegate circle(state, x0, y0, r, opts), to: Draw
  defdelegate rect(state, x, y, width, height, opts), to: Draw
  defdelegate line(state, x1, y1, x2, y2, opts), to: Draw
  defdelegate line_h(state, x, y, width, opts), to: Draw
  defdelegate line_v(state, x, y, height, opts), to: Draw
  defdelegate fill_rect(state, x, y, width, height, opts), to: Draw

  def init_dev(config) do
    case Keyword.get(config, :type) do
      :spi -> SPI.init(config)
      :i2c -> I2C.init(config)
      mod when is_atom(mod) -> mod.init(config)
      _ -> {:error, :unknown_device_type}
    end
  end

  def initialize(config) do
    config = Keyword.merge(@default_config, config)

    with :ok <- validate_config(@required_config, config),
         {:ok, dev} <- init_dev(config) do
      state = %__MODULE__{
        width: config[:width],
        height: config[:height],
        dev: dev,
        external_vcc: config[:external_vcc]
      }

      state
      |> init_display()
      |> clear_buffer(:off)
      |> display()
      |> case do
        %__MODULE__{} = state ->
          {:ok, state}

        error ->
          error
      end
    end
  end

  def init_display(%__MODULE__{} = state) do
    state
    |> reset()
    |> command([@ssd1306_displayoff])
    |> command([@ssd1306_setdisplayclockdiv, 0x80])
    |> command([@ssd1306_setmultiplex, state.height - 1])
    |> command([@ssd1306_setdisplayoffset, 0x0])
    |> command([@ssd1306_setstartline ||| 0x0])
    |> set_chargepump()
    |> command([@ssd1306_memorymode, 0])
    |> command([@ssd1306_segremap ||| 0x1])
    |> command([@ssd1306_comscandec])
    |> set_compins()
    |> set_contrast()
    |> set_precharge()
    |> command([@ssd1306_setvcomdetect, 0x40])
    |> command([@ssd1306_displayallon_resume])
    |> command([@ssd1306_normaldisplay])
    |> command([@ssd1306_deactivate_scroll])
    |> command([@ssd1306_displayon])
  end

  def display(state, opts \\ [])

  def display(%__MODULE__{} = state, opts) do
    %{buffer: buffer, width: width} = state
    opts = Keyword.merge(@display_opts, opts)

    buffer = translate_buffer(buffer, width, opts[:memory_mode])

    display_raw_frame(state, buffer, opts)
  end

  def display(error, _opts),
    do: error

  def display_frame(%__MODULE__{width: width} = state, data, opts) do
    opts = Keyword.merge(@display_opts, opts)

    buffer = translate_buffer(data, width, opts[:memory_mode])

    display_raw_frame(state, buffer, opts)
  end

  def display_raw_frame(%__MODULE__{} = state, data, opts) do
    memory_mode = get_memory_mode(opts[:memory_mode] || :horizontal)

    if byte_size(data) == state.width * state.height / 8 do
      state
      |> command([@ssd1306_memorymode, memory_mode])
      |> command([@ssd1306_pageaddr, 0, trunc(state.height / 8 - 1)])
      |> command([@ssd1306_columnaddr, 0, state.width - 1])
      |> transfer(data)
    else
      {:error, :invalid_data_size}
    end
  end

  def translate_buffer(buffer, width, :horizontal) do
    transformation =
      for x <- 0..(width - 1), y <- 0..7 do
        (7 - y) * width + x
      end

    for <<page::binary-size(width) <- buffer>>, into: <<>> do
      for source <- transformation, into: <<>> do
        rest = width * 8 - source - 1
        <<_::size(source)-unit(1), b::1, _::size(rest)-unit(1)>> = page
        <<b::1>>
      end
    end
  end

  def clear_buffer(%__MODULE__{width: w, height: h} = state, pixel_state)
      when pixel_state in [:on, :off] do
    value =
      case pixel_state do
        :off ->
          <<0::8>>

        :on ->
          <<0xFF::8>>
      end

    buffer =
      for _ <- 1..trunc(w * h / 8), into: <<>> do
        value
      end

    %{state | buffer: buffer}
  end

  def clear_buffer(error, _pixel_state),
    do: error

  def put_buffer(%__MODULE__{} = state, data) do
    if byte_size(data) == state.width * state.height / 8 do
      %{state | buffer: data}
    else
      {:error, :invalid_data_size}
    end
  end

  def get_buffer(%__MODULE__{buffer: buffer}),
    do: {:ok, buffer}

  def get_dimensions(%__MODULE__{width: width, height: height}),
    do: {:ok, width, height}

  defp set_compins(%__MODULE__{height: height} = state) when height > 32,
    do: command(state, [@ssd1306_setcompins, 0x12])

  defp set_compins(%__MODULE__{} = state),
    do: command(state, [@ssd1306_setcompins, 0x02])

  defp set_compins(error),
    do: error

  defp set_contrast(%__MODULE__{width: 128, height: 32} = state),
    do: command(state, [@ssd1306_setcontrast, 0x8F])

  defp set_contrast(%__MODULE__{width: 128, height: 64, external_vcc: true} = state),
    do: command(state, [@ssd1306_setcontrast, 0x9F])

  defp set_contrast(%__MODULE__{width: 128, height: 64, external_vcc: false} = state),
    do: command(state, [@ssd1306_setcontrast, 0xCF])

  defp set_contrast(%__MODULE__{width: 96, height: 16, external_vcc: true} = state),
    do: command(state, [@ssd1306_setcontrast, 0x10])

  defp set_contrast(%__MODULE__{width: 96, height: 16, external_vcc: false} = state),
    do: command(state, [@ssd1306_setcontrast, 0xAF])

  defp set_contrast(error),
    do: error

  defp set_chargepump(%__MODULE__{external_vcc: true} = state),
    do: command(state, [@ssd1306_chargepump, 0x10])

  defp set_chargepump(%__MODULE__{} = state),
    do: command(state, [@ssd1306_chargepump, 0x14])

  defp set_chargepump(error),
    do: error

  defp set_precharge(%__MODULE__{external_vcc: true} = state),
    do: command(state, [@ssd1306_setprecharge, 0x22])

  defp set_precharge(%__MODULE__{} = state),
    do: command(state, [@ssd1306_setprecharge, 0xF1])

  defp set_precharge(error),
    do: error

  defp reset(%__MODULE__{dev: %type{} = dev} = state) do
    case type.reset(dev) do
      %type1{} = dev1 when type1 == type ->
        %{state | dev: dev1}

      error ->
        error
    end
  end

  defp reset(error),
    do: error

  defp transfer(%__MODULE__{dev: %type{} = dev} = state, buffer) do
    case type.transfer(dev, buffer) do
      %type1{} = dev1 when type1 == type ->
        %{state | dev: dev1}

      error ->
        error
    end
  end

  defp transfer(error, _cmd),
    do: error

  def command(%__MODULE__{dev: %type{} = dev} = state, cmds) when is_list(cmds) do
    case Enum.reduce(cmds, dev, fn cmd, dev1 -> type.command(dev1, cmd) end) do
      %type1{} = dev1 when type1 == type ->
        %{state | dev: dev1}

      error ->
        error
    end
  end

  def command(error, _cmd),
    do: error

  defp get_memory_mode(:horizontal), do: 0x00
  defp get_memory_mode(:vertical), do: 0x01
  defp get_memory_mode(:page_addr), do: 0x02
end
