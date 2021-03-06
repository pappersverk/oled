defmodule OLED.Display.Impl.SSD1306.LineTest do
  use ExUnit.Case

  alias OLED.Display.Impl.SSD1306.Draw

  import OLED.BufferTestHelper, only: [build_state: 2, ascii_render: 1]

  @w 32
  @h 8

  test "draw line" do
    assert build_state(@w, @h)
           |> Draw.line(0, 0, 32, 5, [])
           |> ascii_render() == [
             "#######                         ",
             "       ######                   ",
             "             #######            ",
             "                    ######      ",
             "                          ######",
             "                                ",
             "                                ",
             "                                "
           ]
  end

  test "draw many" do
    assert build_state(@w, @h)
           |> Draw.line(0, 0, 32, 8, [])
           |> Draw.line(0, 8, 32, 0, [])
           |> ascii_render() == [
             "####                         ###",
             "    ####                 ####   ",
             "        ####         ####       ",
             "            #### ####           ",
             "             #######            ",
             "         ####       ####        ",
             "     ####               ####    ",
             " ####                       ####"
           ]
  end

  test "draw xor" do
    assert build_state(@w, @h)
           |> Draw.line(0, 0, 32, 8, [])
           |> Draw.line(0, 8, 32, 0, mode: :xor)
           |> ascii_render() == [
             "####                         ###",
             "    ####                 ####   ",
             "        ####         ####       ",
             "            #### ####           ",
             "             ### ###            ",
             "         ####       ####        ",
             "     ####               ####    ",
             " ####                       ####"
           ]
  end

  test "draw line out 1" do
    assert build_state(@w, @h)
           |> Draw.line(4, 4, 35, 10, [])
           |> ascii_render() == [
             "                                ",
             "                                ",
             "                                ",
             "                                ",
             "    ######                      ",
             "          #####                 ",
             "               #####            ",
             "                    #####       "
           ]
  end

  test "draw horizontal rect" do
    assert build_state(@w, @h)
           |> Draw.line(4, 5, 16, 5, [])
           |> ascii_render() ==
             [
               "                                ",
               "                                ",
               "                                ",
               "                                ",
               "                                ",
               "    #############               ",
               "                                ",
               "                                "
             ]
  end

  test "draw vertical rect" do
    assert build_state(@w, @h)
           |> Draw.line(10, 1, 10, 6, [])
           |> ascii_render() ==
             [
               "                                ",
               "          #                     ",
               "          #                     ",
               "          #                     ",
               "          #                     ",
               "          #                     ",
               "          #                     ",
               "                                "
             ]
  end

  test "draw rect out 2" do
    assert build_state(@w, @h)
           |> Draw.line(-32, -8, 32, 8, [])
           |> ascii_render() == [
             "####                            ",
             "    ####                        ",
             "        ####                    ",
             "            ####                ",
             "                ####            ",
             "                    ####        ",
             "                        ####    ",
             "                            ####"
           ]
  end
end
