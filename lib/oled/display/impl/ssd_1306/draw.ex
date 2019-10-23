defmodule OLED.Display.Impl.SSD1306.Draw do
  @moduledoc false

  @bits_per_seg 8

  use Bitwise, only_operators: true

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
end
