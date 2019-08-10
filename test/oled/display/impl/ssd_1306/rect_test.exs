defmodule OLED.Display.Impl.SSD1306.RectTest do
  use ExUnit.Case

  alias OLED.Display.Impl.SSD1306

  import OLED.BufferTestHelper, only: [build_state: 2, ascii_render: 1]

  @w 32
  @h 8

  test "draw rect" do
    assert build_state(@w, @h)
           |> SSD1306.rect(0, 0, 32, 5, [])
           |> ascii_render() == [
             "################################",
             "#                              #",
             "#                              #",
             "#                              #",
             "################################",
             "                                ",
             "                                ",
             "                                "
           ]
  end

  test "draw many" do
    assert build_state(@w, @h)
           |> SSD1306.rect(1, 1, 9, 4, [])
           |> SSD1306.rect(6, 2, 11, 6, [])
           |> ascii_render() == [
             "                                ",
             " #########                      ",
             " #    ###########               ",
             " #    #  #      #               ",
             " #########      #               ",
             "      #         #               ",
             "      #         #               ",
             "      ###########               "
           ]
  end

  test "draw xor" do
    assert build_state(@w, @h)
           |> SSD1306.rect(1, 1, 9, 4, [])
           |> SSD1306.rect(6, 2, 11, 6, mode: :xor)
           |> ascii_render() == [
             "                                ",
             " #########                      ",
             " #    ### #######               ",
             " #    #  #      #               ",
             " ##### ###      #               ",
             "      #         #               ",
             "      #         #               ",
             "      ###########               "
           ]
  end

  test "draw rect out 1" do
    assert build_state(@w, @h)
           |> SSD1306.rect(2, 1, 34, 9, [])
           |> ascii_render() == [
             "                                ",
             "  ##############################",
             "  #                             ",
             "  #                             ",
             "  #                             ",
             "  #                             ",
             "  #                             ",
             "  #                             "
           ]
  end

  test "draw rect out 2" do
    assert build_state(@w, @h)
           |> SSD1306.rect(-5, -5, 10, 10, [])
           |> ascii_render() == [
             "    #                           ",
             "    #                           ",
             "    #                           ",
             "    #                           ",
             "#####                           ",
             "                                ",
             "                                ",
             "                                "
           ]
  end
end
