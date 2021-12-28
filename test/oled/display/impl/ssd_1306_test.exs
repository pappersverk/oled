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

  describe "display/2" do
    test "with valid data" do
      data =
        for v <- 1..8, into: <<>> do
          <<v>>
        end

      state = %SSD1306{
        dev: %DummyDev{},
        width: 8,
        height: 8,
        buffer: data
      }

      assert %SSD1306{buffer: buffer} = SSD1306.display(state, [])
      assert buffer = <<0, 0, 0, 0, 128, 120, 102, 85>>
    end
  end

  describe "display_frame/2" do
    test "with valid data" do
      data =
        for v <- 1..8, into: <<>> do
          <<v>>
        end

      state = %SSD1306{
        dev: %DummyDev{},
        width: 8,
        height: 8,
      }

      assert %SSD1306{} = SSD1306.display_frame(state, data, [])

      assert_received {:command, 32}
      assert_received {:command, 0}
      assert_received {:transfer, <<0, 0, 0, 0, 128, 120, 102, 85>>}
    end
  end

  describe "display_raw_frame/2" do
    test "with valid data" do
      state = %SSD1306{
        dev: %DummyDev{},
        width: 96,
        height: 48
      }

      data =
        for _ <- 1..576, into: <<>> do
          <<0>>
        end

      assert %SSD1306{} = SSD1306.display_raw_frame(state, data, memory_mode: :vertical)

      assert_received {:command, 32}
      assert_received {:command, 1}
      assert_received {:transfer, ^data}
    end

    test "with invalid data" do
      state = %SSD1306{
        dev: %DummyDev{},
        width: 96,
        height: 48
      }

      data =
        for _ <- 1..200, into: <<>> do
          <<0>>
        end

      assert {:error, :invalid_data_size} =
               SSD1306.display_raw_frame(state, data, memory_mode: :vertical)
    end
  end

  describe "put_buffer/1" do
    test "with valid data" do
      state = %SSD1306{
        dev: %DummyDev{},
        width: 8,
        height: 8,
      }

      data =
        for v <- 1..8, into: <<>> do
          <<v>>
        end

      assert %SSD1306{buffer: buffer} = SSD1306.put_buffer(state, data)

      assert buffer = <<0, 0, 0, 0, 128, 120, 102, 85>>
    end

    test "with invalid data" do
      state = %SSD1306{
        dev: %DummyDev{},
        width: 8,
        height: 8
      }

      data =
        for v <- 1..16, into: <<>> do
          <<v>>
        end

      assert {:error, :invalid_data_size} =
               SSD1306.put_buffer(state, data)
    end
  end

  describe "get_buffer/0" do
    test "with valid data" do
      data =
        for v <- 1..8, into: <<>> do
          <<v>>
        end

      state = %SSD1306{
        dev: %DummyDev{},
        width: 8,
        height: 8,
        buffer: data
      }

      assert {:ok, buffer} = SSD1306.get_buffer(state)
      assert buffer = <<0, 0, 0, 0, 128, 120, 102, 85>>
    end
  end

  describe "translate_buffer/3" do
    test "with valid data" do
      # Buffer is generated using the following draw functions:
      # buffer =
      #   OLED.BufferTestHelper.build_state(32, 16)
      #   |> OLED.Display.Impl.SSD1306.Draw.line_h(1, 0, 30, [])
      #   |> OLED.Display.Impl.SSD1306.Draw.line_h(1, 15, 30, [])
      #   |> OLED.Display.Impl.SSD1306.Draw.line_v(0, 1, 14, [])
      #   |> OLED.Display.Impl.SSD1306.Draw.line_v(31, 1, 14, [])
      #   |> OLED.Display.Impl.SSD1306.Draw.circle(10, 8, 6, [])
      #   |> OLED.Display.Impl.SSD1306.Draw.circle(21, 8, 6, [])
      #   |> Map.get(:buffer)

      buffer = <<127, 255, 255, 254, 128, 0, 0, 1, 128, 248, 31, 1, 131, 6, 96, 193, 132, 1,
        128, 33, 132, 1, 128, 33, 136, 1, 128, 17, 136, 1, 128, 17, 136, 1, 128, 17,
        136, 1, 128, 17, 136, 1, 128, 17, 132, 1, 128, 33, 132, 1, 128, 33, 131, 6,
        96, 193, 128, 248, 31, 1, 127, 255, 255, 254>>

      assert SSD1306.translate_buffer(buffer, 32, :horizontal)
        == <<254, 1, 1, 1, 193, 49, 9, 9, 5, 5, 5, 5, 5, 9, 9, 241, 241, 9, 9, 5, 5, 5, 5,
               5, 9, 9, 49, 193, 1, 1, 1, 254, 127, 128, 128, 128, 135, 152, 160, 160, 192,
               192, 192, 192, 192, 160, 160, 159, 159, 160, 160, 192, 192, 192, 192, 192,
               160, 160, 152, 135, 128, 128, 128, 127>>
    end
  end
end
