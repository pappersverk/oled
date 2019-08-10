defmodule OLED.Display.Impl.SSD1306 do
  @moduledoc false

  alias Circuits.{GPIO, SPI}

  alias OLED.Image

  use Bitwise, only_operators: true

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
  # @ssd1306_externalvcc 0x1
  # @ssd1306_switchcapvcc 0x2

  # Full width of SSD1306 controller memory
  @lcd_total_width 128
  # Full height of SSD1306 controller memory
  @lcd_total_height 64

  @spi_speed 8_000_000

  @default_config [
    width: 128,
    height: 64
  ]

  @bits_per_seg 8

  @required_config [
    :spi_dev,
    :dc_pin,
    :rst_pin
  ]

  defstruct width: nil,
            height: nil,
            rst: nil,
            spi: nil,
            dc: nil,
            buffer: nil

  def initialize(config) do
    config = Keyword.merge(@default_config, config)

    with :ok <- validate_config(config),
         {:ok, rst} <- GPIO.open(config[:rst_pin], :output),
         {:ok, dc} <- GPIO.open(config[:dc_pin], :output),
         {:ok, spi} <- SPI.open(config[:spi_dev], speed_hz: @spi_speed) do
      state = %__MODULE__{
        width: config[:width],
        height: config[:height],
        rst: rst,
        dc: dc,
        spi: spi
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

  defp validate_config(config) do
    Enum.reduce_while(@required_config, nil, fn key, _ ->
      if Keyword.has_key?(config, key) do
        {:cont, :ok}
      else
        {:halt, {:error, {:missed_config, key}}}
      end
    end)
  end

  def rect(state, x, y, width, height, opts) do
    state =
      state
      |> line_h(x, y, width, opts)
      |> line_h(x, y + height - 1, width, opts)

    int_height = height - 2

    if int_height > 0 do
      state
      |> line_v(x, y + 1, int_height, opts)
      |> line_v(x + width - 1, y + 1, int_height, opts)
    else
      state
    end
  end

  def image(state, path, x, y, opts) do
    with {:ok, %Image{data: data}} <- Image.load_binarized(path, opts) do
      opts_on = Keyword.merge(opts, state: :on)
      opts_off = Keyword.merge(opts, state: :off)

      Enum.with_index(data)
      |> Enum.map(fn {list, y} ->
        list
        |> Enum.with_index()
        |> Enum.map(fn {p, x} ->
          {x, y, p}
        end)
      end)
      |> List.flatten()
      |> Enum.reduce(state, fn
        {ix, iy, true}, acc ->
          put_pixel(acc, x + ix, y + iy, opts_on)

        {ix, iy, false}, acc ->
          put_pixel(acc, x + ix, y + iy, opts_off)

        _, acc ->
          acc
      end)
    end
  end

  def put_pixel(%{width: w, height: h} = state, x, y, opts)
      when x >= 0 and x < w and y >= 0 and y < h do
    %{buffer: buffer, width: width} = state

    seg_offset = x + trunc(y / @bits_per_seg) * width

    <<
      prev::bytes-size(seg_offset),
      seg::bytes-size(1),
      rest::binary
    >> = buffer

    seg_value =
      calc_seg_value(
        seg,
        y,
        opts[:state] || :on,
        opts[:mode] || :normal
      )

    buffer = build_buffer(prev, seg_value, rest)

    %{state | buffer: buffer}
  end

  def put_pixel(state, _x, _y, _opts),
    do: state

  def line(state, x1, y1, x2, y2, opts) do
    # sort points
    {x1, y1, x2, y2} =
      if x1 > x2 do
        {x2, y2, x1, y1}
      else
        {x1, y1, x2, y2}
      end

    dx = x2 - x1
    dy = y2 - y1

    Enum.reduce(x1..x2, state, fn x, acc ->
      y = trunc(y1 + dy * (x - x1) / dx)
      put_pixel(acc, x, y, opts)
    end)
  end

  def line_h(state, x, y, width, opts) do
    cond do
      x < 0 and width + x < 0 ->
        :skip

      x >= state.width ->
        :skip

      y >= state.height ->
        :skip

      y < 0 ->
        :skip

      true ->
        x2 =
          cond do
            x < 0 -> 0
            x > state.width - 1 -> state.width - 1
            true -> x
          end

        y2 =
          cond do
            y < 0 -> 0
            y > state.height - 1 -> state.height - 1
            true -> y
          end

        width2 = width - (x2 - x)

        {x2, y2, width2}
    end
    |> case do
      {x, y, width} ->
        seg_offset = x + trunc(y / @bits_per_seg) * state.width

        total_segs =
          if width > state.width - x do
            state.width - x
          else
            width
          end

        <<
          prev::bytes-size(seg_offset),
          seg::bytes-size(total_segs),
          rest::binary
        >> = state.buffer

        seg =
          write_line_h(
            seg,
            y,
            opts[:state] || :on,
            opts[:mode] || :normal
          )

        buffer = <<prev <> seg <> rest>>

        %{state | buffer: buffer}

      :skip ->
        state
    end
  end

  def line_v(state, _x, _y, height, _opts) when height < 1,
    do: state

  def line_v(state, x, y, height, opts) do
    state
    |> put_pixel(x, y, opts)
    |> line_v(x, y + 1, height - 1, opts)
  end

  defp write_line_h(<<s::bytes-size(1), tail::binary>>, y, state, mode) do
    seg_value =
      calc_seg_value(
        s,
        y,
        state,
        mode
      )

    <<(<<seg_value>> <> write_line_h(tail, y, state, mode))>>
  end

  defp write_line_h(<<>>, _y, _state, _mode),
    do: <<>>

  defp build_buffer(prev, seg_value, rest) do
    seg = <<seg_value>>

    <<prev <> seg <> rest>>
  end

  defp calc_seg_value(<<seg_value>>, y, :on, :normal),
    do: seg_value ||| 1 <<< rem(y, @bits_per_seg)

  defp calc_seg_value(<<seg_value>>, y, :off, :normal),
    do: seg_value &&& ~~~(1 <<< rem(y, @bits_per_seg))

  defp calc_seg_value(<<seg_value>>, y, :on, :xor),
    do: seg_value ^^^ (1 <<< rem(y, @bits_per_seg))

  defp calc_seg_value(<<seg_value>>, _y, _state, _mode),
    do: seg_value

  def init_display(state) do
    state
    |> reset()
    |> command(<<@ssd1306_displayoff>>)
    |> command(<<@ssd1306_setdisplayclockdiv, 0x80>>)
    |> command(<<@ssd1306_setmultiplex, 0x3F>>)
    |> command(<<@ssd1306_setdisplayoffset, 0x0>>)
    |> command(<<@ssd1306_setstartline ||| 0x0>>)
    |> command(<<@ssd1306_chargepump, 0x14>>)
    |> command(<<@ssd1306_normaldisplay>>)
    |> command(<<@ssd1306_displayallon_resume>>)
    |> command(<<@ssd1306_segremap ||| 0x1>>)
    |> command(<<@ssd1306_comscandec>>)
    |> set_compins()
    |> command(<<@ssd1306_setcontrast, 0xCF>>)
    |> command(<<@ssd1306_setprecharge, 0xF1>>)
    |> command(<<@ssd1306_setvcomdetect, 0x40>>)
    |> command(<<@ssd1306_displayon>>)
  end

  def reset(%__MODULE__{} = state) do
    with :ok <- GPIO.write(state.rst, 1),
         _ <- :timer.sleep(5),
         :ok <- GPIO.write(state.rst, 0),
         _ <- :timer.sleep(10),
         :ok <- GPIO.write(state.rst, 1),
         _ <- :timer.sleep(100) do
      state
    else
      _ ->
        {:error, :display_reset}
    end
  end

  def display(state) do
    state =
      state
      |> command(<<@ssd1306_memorymode, 0>>)
      |> command(<<@ssd1306_columnaddr, 0, @lcd_total_width - 1>>)
      |> command(<<@ssd1306_pageaddr, 0, trunc(@lcd_total_height / 8 - 1)>>)

    with %__MODULE__{} <- state,
         :ok <- GPIO.write(state.dc, 1),
         {:ok, _} <- SPI.transfer(state.spi, state.buffer) do
      # Restore to page addressing mode
      command(state, <<@ssd1306_memorymode, 2>>)
    end
  end

  def command({:error, _} = error, _cmd),
    do: error

  def command(%__MODULE__{} = state, cmd) when is_binary(cmd) do
    with :ok <- GPIO.write(state.dc, 0),
         {:ok, _} <- SPI.transfer(state.spi, cmd) do
      state
    else
      error ->
        {:error, {:cmd, cmd, error}}
    end
  end

  def clear_buffer(state, pixel_state)
      when pixel_state in [:on, :off] do
    value =
      case pixel_state do
        :off ->
          <<0::8>>

        :on ->
          <<0xFF::8>>
      end

    buffer =
      for _ <- 1..trunc(@lcd_total_width * @lcd_total_height / 8), into: <<>> do
        value
      end

    %{state | buffer: buffer}
  end

  defp set_compins(%__MODULE__{width: width} = state) when width > 32,
    do: command(state, <<@ssd1306_setcompins, 0x12>>)

  defp set_compins(%__MODULE__{} = state),
    do: command(state, <<@ssd1306_setcompins, 0x02>>)

  defp set_compins(error),
    do: error
end
