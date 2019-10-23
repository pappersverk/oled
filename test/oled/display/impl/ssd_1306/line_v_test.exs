defmodule OLED.Display.Impl.SSD1306.LineVTest do
  use ExUnit.Case

  alias OLED.Display.Impl.SSD1306.Draw

  import OLED.BufferTestHelper, only: [build_state: 2, ascii_render: 1]

  @w 32
  @h 8

  test "draw inside" do
    assert build_state(@w, @h)
           |> Draw.line_v(1, 1, 5, [])
           |> ascii_render() == [
             "                                ",
             " #                              ",
             " #                              ",
             " #                              ",
             " #                              ",
             " #                              ",
             "                                ",
             "                                "
           ]
  end

  test "draw out 1" do
    assert build_state(@w, @h)
           |> Draw.line_v(-4, 1, 5, [])
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

  test "draw out 2" do
    assert build_state(@w, @h)
           |> Draw.line_v(33, 1, 5, [])
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

  test "draw out 3" do
    assert build_state(@w, @h)
           |> Draw.line_v(1, -5, 8, [])
           |> ascii_render() == [
             " #                              ",
             " #                              ",
             " #                              ",
             "                                ",
             "                                ",
             "                                ",
             "                                ",
             "                                "
           ]
  end

  test "draw out 4" do
    assert build_state(@w, @h)
           |> Draw.line_v(5, 5, 8, [])
           |> ascii_render() == [
             "                                ",
             "                                ",
             "                                ",
             "                                ",
             "                                ",
             "     #                          ",
             "     #                          ",
             "     #                          "
           ]
  end
end
