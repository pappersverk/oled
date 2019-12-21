defmodule OLED.Display.Impl.SSD1306.CircleTest do
  use ExUnit.Case

  alias OLED.Display.Impl.SSD1306.Draw

  import OLED.BufferTestHelper, only: [build_state: 2, ascii_render: 1]

  @w 32
  @h 20

  test "draw circles" do
    assert build_state(@w, @h)
           |> Draw.circle(5, 5, 5, [])
           |> Draw.circle(10, 10, 6, [])
           |> ascii_render() == [
             "   #####                        ",
             "  #     #                       ",
             " #       #                      ",
             "#         #                     ",
             "#       #####                   ",
             "#     ##  #  ##                 ",
             "#    #    #    #                ",
             "#    #    #    #                ",
             " #  #    #      #               ",
             "  # #   #       #               ",
             "   #####        #               ",
             "    #           #               ",
             "    #           #               ",
             "     #         #                ",
             "     #         #                ",
             "      ##     ##                 ",
             "        #####                   ",
             "                                ",
             "                                ",
             "                                "
           ]
  end
end
