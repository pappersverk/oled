defmodule OLED.Display.Impl.SSD1306Test do
  use ExUnit.Case, async: true
  alias OLED.DummyDev
  alias OLED.Display.Impl.SSD1306

  test "command/2" do
    state = %SSD1306{
      dev: %DummyDev{}
    }

    assert %SSD1306{} = SSD1306.command(state, [1, 2, 3])

    assert_received {:command, 1}
    assert_received {:command, 2}
    assert_received {:command, 3}
  end
end
