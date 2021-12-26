# OLED

![Test Status](https://github.com/pappersverk/oled/actions/workflows/tests.yml/badge.svg)
[![Hex version](https://img.shields.io/hexpm/v/oled.svg "Hex version")](https://hex.pm/packages/oled)


OLED is a library to manage the monochrome OLED screen based (for now) on chip SSD1306 connected by SPI or I2C.

The idea is to support other similar chips also.

NOTE: On OLED v0.3.0 the Scenic driver has been moved to [scenic_driver_oled](https://github.com/pappersverk/scenic_driver_oled).

![Sample](images/sample.jpeg)

## Features

Graphic primitives
- [x] Points
- [x] Lines
- [x] Rects
- [x] Filled Rects
- [x] Circles
- [ ] Filled Circles
- [ ] Polygons
- [ ] Filled Polygons
- [ ] Text rendering (Try [Chisel](https://github.com/luisgabrielroldan/chisel))



<p align="center">
  <br>
  <br>
  <img src="images/scenic_preview.gif"><br>
  Using OLED and Scenic
  <br>
</p>




## Basic Setup

*1. edit your mix.exs*

```elixir
def deps do
  [
    {:oled, "~> 0.3.4"}
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

