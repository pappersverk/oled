defmodule OLED.Display.Impl.SSD1306.LineHTest do
  use ExUnit.Case

  alias OLED.Display.Impl.SSD1306.Draw

  import OLED.BufferTestHelper, only: [build_state: 2, ascii_render: 1]

  @w 32
  @h 8

  test "draw inside" do
    assert build_state(@w, @h)
           |> Draw.line_h(1, 1, 10, [])
           |> ascii_render() == [
             "                                ",
             " ##########                     ",
             "                                ",
             "                                ",
             "                                ",
             "                                ",
             "                                ",
             "                                "
           ]
  end

  test "draw out 1" do
    assert build_state(@w, @h)
           |> Draw.line_h(-4, 1, 8, [])
           |> ascii_render() == [
             "                                ",
             "####                            ",
             "                                ",
             "                                ",
             "                                ",
             "                                ",
             "                                ",
             "                                "
           ]
  end

  test "draw out 2" do
    assert build_state(@w, @h)
           |> Draw.line_h(30, 1, 8, [])
           |> ascii_render() == [
             "                                ",
             "                              ##",
             "                                ",
             "                                ",
             "                                ",
             "                                ",
             "                                ",
             "                                "
           ]
  end

  test "draw out 3" do
    assert build_state(@w, @h)
           |> Draw.line_h(-10, 1, 8, [])
           |> ascii_render() == [
             "                                ",
             "                                ",
             "                                ",
             "                                ",
             "                                ",
             "                                ",
             "                                ",
             "                                "
           ]
  end

  test "draw out 4" do
    assert build_state(@w, @h)
           |> Draw.line_h(32, 1, 8, [])
           |> ascii_render() == [
             "                                ",
             "                                ",
             "                                ",
             "                                ",
             "                                ",
             "                                ",
             "                                ",
             "                                "
           ]
  end
end
