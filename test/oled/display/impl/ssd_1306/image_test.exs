defmodule OLED.Display.Impl.SSD1306.ImageTest do
  use ExUnit.Case

  alias OLED.Display.Impl.SSD1306

  import OLED.BufferTestHelper, only: [build_state: 2, ascii_render: 1]

  @w 8
  @h 8

  test "draw image" do
    assert build_state(@w, @h)
           |> SSD1306.image("test/fixtures/images/rgba8.png", 0, 0, threshold: 120)
           |> ascii_render() == [
             "        ",
             " ###    ",
             " ###    ",
             " ###    ",
             "        ",
             "        ",
             "        ",
             "        "
           ]
  end

  test "draw skipping alpha" do
    assert build_state(@w, @h)
           |> SSD1306.line(0, 0, 8, 8, [])
           |> SSD1306.image("test/fixtures/images/rgba8.png", 0, 0, threshold: 120)
           |> ascii_render() == [
             "#       ",
             " ###    ",
             " ###    ",
             " ###    ",
             "    #   ",
             "     #  ",
             "      # ",
             "       #"
           ]
  end

  test "draw xor mode" do
    assert build_state(@w, @h)
           |> SSD1306.line(0, 0, 8, 8, [])
           |> SSD1306.image("test/fixtures/images/rgba8.png", 0, 0, threshold: 120, mode: :xor)
           |> ascii_render() == [
             "#       ",
             "  ##    ",
             " # #    ",
             " ##     ",
             "    #   ",
             "     #  ",
             "      # ",
             "       #"
           ]
  end
end
