# OLED

[![Hex version](https://img.shields.io/hexpm/v/oled.svg "Hex version")](https://hex.pm/packages/oled)


OLED is a library to manage the monochrome OLED screen based (for now) on chip SSD1306 connected by SPI or I2C.

The idea is to support other similar chips also.

![Sample](images/sample.jpeg)

## Features

Graphic primitives
- [x] Points
- [x] Lines
- [x] Rects
- [ ] Circles
- [ ] Polygons
- [ ] Filled Rects
- [ ] Filled Circles
- [ ] Filled Polygons

## Basic Setup

*1. edit your mix.exs*

```elixir
def deps do
  [
    {:oled, "~> 0.1.0"}
  ]
end
```

*2. create a display module*

```elixir
defmodule MyApp.MyDisplay do
  use OLED.Display, app: :my_app

end
```

*3. add the configuration*

```elixir
config :my_app, MyApp.MyDisplay,
  device: "spidev0.0",
  driver: :ssd1306,
  type: :spi,
  width: 128,
  height: 64,
  rst_pin: 25,
  dc_pin: 24
```

*4. add your application's supervision tree*
```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Add this line
      MyApp.MyDisplay
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

*5. use it*

```elixir
  # Draw something
  MyApp.MyDisplay.rect(0, 0, 127, 63)
  MyApp.MyDisplay.line(0, 0, 127, 63)
  MyApp.MyDisplay.line(0, 63, 127, 0)

  # Display it!
  MyApp.MyDisplay.display()
```

## Displays configuration

```elixir
config :my_app, MyApp.MyDisplay,
  device: "spidev0.0",  # Device (i.e.: `spidev0.0`, `i2c-1`, ...)
  driver: :ssd1306,     # Driver. (Only SSD1306 for now)
  type: :spi,           # Connection type: `:spi` or `:i2c`
  width: 128,           # Display Width
  height: 64,           # Display Height
  rst_pin: 25,          # Reset GPIO pin (SPI only)
  dc_pin: 24            # DC GPIO pin (SPI only)
  address: 0x3C         # DC GPIO pin (I2C only)
```

## Scenic Driver

OLED is compatible with [Scenic](https://github.com/boydm/scenic) thanks to [rpi_fb_capture](https://github.com/fhunleth/rpi_fb_capture).

*1. Add the dependencies*

```elixir
def deps do
  [
    {:oled, "~> 0.1.0"},
    {:scenic, "~> 0.10"},
    {:scenic_driver_nerves_rpi, "~> 0.10", targets: @all_targets},
    {:rpi_fb_capture, "~> 0.1.0"}
  ]
end
```

*2. Configure the driver*

Passing the configuration for the display...

```elixir
config :my_app, :viewport, %{
  name: :main_viewport,
  default_scene: {MyApp.Scene.Default, nil},
  size: {128, 64},
  opts: [scale: 1.0],
  drivers: [
    %{
      module: OLED.Scenic.Driver,
      opts: [
        display: [
          driver: :ssd1306,
          type: :i2c,
          device: "i2c-1",
          address: 60,
          width: 128,
          height: 32
        ]
      ]
    }
  ]
}
```


... or the display module if you have one (Check the Basic Setup):

```elixir
config :my_app, :viewport, %{
  name: :main_viewport,
  default_scene: {MyApp.Scene.Default, nil},
  size: {128, 64},
  opts: [scale: 1.0],
  drivers: [
    %{
      module: OLED.Scenic.Driver,
      opts: [
        display: MyApp.MyDisplay
      ]
    }
  ]
}

```

## Thanks

Special thanks to [@nerves-training](https://github.com/nerves-training) where I've seen for the first time approach of use `rp_fb_capture` in [scenic_driver_oled_bonnet](https://github.com/nerves-training/scenic_driver_oled_bonnet) to implement a Scenic driver.


