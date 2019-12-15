defmodule OLED.Display.Impl.SSD1306.Draw do
  @moduledoc false

  use Bitwise, only_operators: true

  def put_pixel(%{width: w, height: h} = state, x, y, opts)
      when x >= 0 and x < w and y >= 0 and y < h do
    %{buffer: buffer, width: width} = state

    offset = width * y + x

    <<prev::bitstring-size(offset), p::1, next::bitstring>> = buffer

    pixel_state = opts[:state] || :on
    mode = opts[:mode] || :normal

    np = if pixel_state == :on, do: 1, else: 0

    np =
      case mode do
        :normal -> p ||| np
        :xor -> p ^^^ np
      end

    buffer = <<prev::bitstring, np::1, next::bitstring>>

    %{state | buffer: buffer}
  end

  def put_pixel(state, _x, _y, _opts),
    do: state

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

  def line_h(state, _x, _y, width, _opts) when width < 1,
    do: state

  def line_h(state, x, y, width, opts) do
    state
    |> put_pixel(x, y, opts)
    |> line_h(x + 1, y, width - 1, opts)
  end

  def line_v(state, _x, _y, height, _opts) when height < 1,
    do: state

  def line_v(state, x, y, height, opts) do
    state
    |> put_pixel(x, y, opts)
    |> line_v(x, y + 1, height - 1, opts)
  end
end
