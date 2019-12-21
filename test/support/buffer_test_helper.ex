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
        1 ->
          "#"

        0 ->
          " "
      end)
      |> Enum.join()
    end)
  end

  defp decode_buffer(buffer, w) do
    for(<<b::1 <- buffer>>, do: b)
    |> Enum.chunk_every(w)
  end

  defp empty_buffer(w, h, v) do
    for _ <- 1..trunc(w * h / 8), into: <<>> do
      <<v::8>>
    end
  end
end
