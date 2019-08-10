defmodule OLED.BufferTestHelper do
  alias OLED.Display.Impl.SSD1306
  use Bitwise

  def build_state(w, h, v \\ 0) do
    %SSD1306{
      width: w,
      height: h,
      buffer: empty_buffer(w, h, v)
    }
  end

  def ascii_render(%{buffer: buffer, width: w}) do
    buffer
    |> decode_buffer(w)
    |> Enum.map(fn line ->
      Enum.map(line, fn
        true ->
          "#"

        _ ->
          " "
      end)
      |> Enum.join()
    end)
  end

  defp test_bit(v, b),
    do: (v &&& 1 <<< b) != 0

  defp decode_buffer(buffer, w) do
    buffer
    |> to_bytes([])
    |> Enum.chunk_every(w)
    |> Enum.map(&decode_page(&1, w))
    |> List.flatten()
    |> Enum.chunk_every(w)
  end

  defp decode_page(bytes, w) do
    ry = 0..7
    rx = 0..(w - 1)

    for y <- ry do
      for x <- rx do
        bytes
        |> Enum.at(x)
        |> test_bit(y)
      end
    end
  end

  defp to_bytes(<<byte::bytes-size(1), rest::binary()>>, acc) do
    <<byte_value>> = byte
    acc = acc ++ [byte_value]

    to_bytes(rest, acc)
  end

  defp to_bytes(<<>>, acc),
    do: acc

  defp empty_buffer(w, h, v \\ 0) do
    for _ <- 1..trunc(w * h / 8), into: <<>> do
      <<v::8>>
    end
  end
end
