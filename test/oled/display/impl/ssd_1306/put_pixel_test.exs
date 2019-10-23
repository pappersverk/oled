defmodule OLED.Display.Impl.SSD1306.PutPixelTest do
  use ExUnit.Case

  alias OLED.Display.Impl.SSD1306.Draw

  import OLED.BufferTestHelper, only: [build_state: 2, ascii_render: 1]

  @w 8
  @h 8

  test "draw pixel" do
    assert build_state(@w, @h)
           |> Draw.put_pixel(1, 1, [])
           |> Draw.put_pixel(2, 2, state: :off)
           |> ascii_render() == [
             "        ",
             " #      ",
             "        ",
             "        ",
             "        ",
             "        ",
             "        ",
             "        "
           ]
  end

  test "draw many" do
    assert build_state(@w, @h)
           |> Draw.put_pixel(1, 1, [])
           |> Draw.put_pixel(2, 2, [])
           |> ascii_render() == [
             "        ",
             " #      ",
             "  #     ",
             "        ",
             "        ",
             "        ",
             "        ",
             "        "
           ]
  end

  test "draw xor" do
    assert build_state(@w, @h)
           |> Draw.put_pixel(1, 1, [])
           |> Draw.put_pixel(1, 1, mode: :xor)
           |> ascii_render() == [
             "        ",
             "        ",
             "        ",
             "        ",
             "        ",
             "        ",
             "        ",
             "        "
           ]
  end

  test "draw rect out 1" do
    assert build_state(@w, @h)
           |> Draw.put_pixel(20, 20, [])
           |> ascii_render() == [
             "        ",
             "        ",
             "        ",
             "        ",
             "        ",
             "        ",
             "        ",
             "        "
           ]
  end

  test "draw rect out 2" do
    assert build_state(@w, @h)
           |> Draw.put_pixel(-5, -5, [])
           |> ascii_render() == [
             "        ",
             "        ",
             "        ",
             "        ",
             "        ",
             "        ",
             "        ",
             "        "
           ]
  end
end
