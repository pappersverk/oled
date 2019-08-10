defmodule OLED.ImageTest do
  use ExUnit.Case

  alias OLED.Image

  describe "load_binarized/2" do
    test "load png:rgba16" do
      assert Image.load_binarized("test/fixtures/images/rgba16.png") ==
               {:ok,
                %Image{
                  width: 5,
                  height: 5,
                  data: [
                    [nil, nil, nil, nil, nil],
                    [nil, true, true, true, nil],
                    [nil, true, true, true, nil],
                    [nil, true, true, true, nil],
                    [nil, nil, nil, nil, nil]
                  ]
                }}
    end

    test "load png:rgba8" do
      assert Image.load_binarized("test/fixtures/images/rgba8.png") ==
               {:ok,
                %Image{
                  width: 5,
                  height: 5,
                  data: [
                    [nil, nil, nil, nil, nil],
                    [nil, true, true, true, nil],
                    [nil, true, true, true, nil],
                    [nil, true, true, true, nil],
                    [nil, nil, nil, nil, nil]
                  ]
                }}
    end

    test "load png:rgb16" do
      assert Image.load_binarized("test/fixtures/images/rgb16.png") ==
               {:ok,
                %Image{
                  width: 5,
                  height: 5,
                  data: [
                    [false, false, false, false, false],
                    [true, true, true, true, true],
                    [true, true, true, true, true],
                    [true, true, true, true, true],
                    [false, false, false, false, false]
                  ]
                }}
    end

    test "load png:rgb8" do
      assert Image.load_binarized("test/fixtures/images/rgb8.png") ==
               {:ok,
                %Image{
                  width: 5,
                  height: 5,
                  data: [
                    [false, false, false, false, false],
                    [true, true, true, true, true],
                    [true, true, true, true, true],
                    [true, true, true, true, true],
                    [false, false, false, false, false]
                  ]
                }}
    end

    test "load png:gray8" do
      assert Image.load_binarized("test/fixtures/images/gray8.png") ==
               {:ok,
                %Image{
                  width: 5,
                  height: 5,
                  data: [
                    [true, true, true, true, true],
                    [true, true, true, true, true],
                    [true, true, true, true, true],
                    [true, true, true, true, true],
                    [false, false, false, false, false]
                  ]
                }}
    end

    test "load png:graya8" do
      assert Image.load_binarized("test/fixtures/images/graya8.png") ==
               {:ok,
                %Image{
                  width: 5,
                  height: 5,
                  data: [
                    [nil, nil, nil, nil, nil],
                    [nil, true, true, true, nil],
                    [nil, true, true, true, nil],
                    [nil, true, true, true, nil],
                    [nil, nil, nil, nil, nil]
                  ]
                }}
    end
  end
end
