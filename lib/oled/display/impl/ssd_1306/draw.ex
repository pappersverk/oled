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
        :normal -> np
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

  def fill_rect(state, x, y, width, height, opts) do
    Enum.reduce(y..(y + height), state, fn y1, state ->
      line_h(state, x, y1, width, opts)
    end)
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

  def circle(state, x0, y0, r, opts) do
    x = 0
    y = r

    state =
      state
      |> put_pixel(x0, y0 + r, opts)
      |> put_pixel(x0, y0 - r, opts)
      |> put_pixel(x0 + r, y0, opts)
      |> put_pixel(x0 - r, y0, opts)

    draw_circle(x0, y0, x, y, 1 - r, 1, -2 * r, opts, state)
  end

  defp draw_circle(x0, y0, x, y, f, ddF_x, ddF_y, opts, state)
       when x < y do
    {y, ddF_y, f} =
      if f >= 0 do
        {y - 1, ddF_y + 2, f + ddF_y}
      else
        {y, ddF_y, f}
      end

    x = x + 1
    ddF_x = ddF_x + 2
    f = f + ddF_x

    state =
      state
      |> put_pixel(x0 + x, y0 + y, opts)
      |> put_pixel(x0 - x, y0 + y, opts)
      |> put_pixel(x0 + x, y0 - y, opts)
      |> put_pixel(x0 - x, y0 - y, opts)
      |> put_pixel(x0 + y, y0 + x, opts)
      |> put_pixel(x0 - y, y0 + x, opts)
      |> put_pixel(x0 + y, y0 - x, opts)
      |> put_pixel(x0 - y, y0 - x, opts)

    draw_circle(x0, y0, x, y, f, ddF_x, ddF_y, opts, state)
  end

  defp draw_circle(_x0, _y0, _x, _y, _f, _ddF_x, _ddF_y, _opts, state),
    do: state
end
