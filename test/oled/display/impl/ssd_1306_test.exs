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
end
