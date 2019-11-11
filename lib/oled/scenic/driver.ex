defmodule OLED.Scenic.Driver do
  @moduledoc """
  ## Requirements
  
  The Scenic driver requires `rpi_fb_capture` and `scenic_driver_nerves_rpi` to work:
  
  ```elixir
    {:scenic_driver_nerves_rpi, "~> 0.10", targets: @all_targets},
    {:rpi_fb_capture, "~> 0.3.0"}
  ```

  ## Configuration
  
  The driver can be configured in two ways:

  Passing the entire configuration for the display:

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
          ],
          dithering: :sierra
        ]
      }
    ]
  }
  ```


  Passing the display module:

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
          display: MyApp.MyDisplay,
          dithering: :sierra
        ]
      }
    ]
  }

  ```

  ### Dithering
  
  OLED takes avatage of the `rpi_db_capture` dithering feature to improve the visualization.

  The current modes supported for the `dithering` key are:
    * `:none` - No dithering applied
    * `:floyd_steinberg` - Floyd–Steinberg
    * `:sierra` - Sierra (also called Sierra-3)
    * `:sierra_2row` - Two-row Sierra
    * `:sierra_lite` - Sierra Lite

  """
  if Code.ensure_loaded?(Scenic.ViewPort.Driver) and
       Code.ensure_loaded?(Scenic.Driver.Nerves.Rpi) and
       Code.ensure_loaded?(RpiFbCapture) do
    use Scenic.ViewPort.Driver

    @impl true
    def init(viewport, size, config) do
      vp_supervisor = vp_supervisor(viewport)
      rpi_driver_config = {vp_supervisor, size, %{module: Scenic.Driver.Nerves.Rpi}}

      with {:ok, rpi_driver} <- Scenic.ViewPort.Driver.start_link(rpi_driver_config),
           {:ok, display} <- get_display(config[:display]),
           {:ok, width, height} <- OLED.Display.Server.get_dimensions(display),
           {:ok, cap} <- RpiFbCapture.start_link(width: width, height: height, display: 0) do
        configure_dithering(cap, config[:dithering])

        send(self(), :capture)

        {:ok,
         %{
           viewport: viewport,
           display: display,
           cap: cap,
           rpi_driver: rpi_driver,
           last_crc: -1
         }}
      else
        error ->
          {:stop, error}
      end
    end

    @impl true
    def handle_info(:capture, state) do
      {:ok, frame} = RpiFbCapture.capture(state.cap, :mono_column_scan)

      crc = :erlang.crc32(frame.data)

      if crc != state.last_crc do
        OLED.Display.Server.display_frame(state.display, frame.data, memory_mode: :vertical)
      end

      Process.send_after(self(), :capture, 50)
      {:noreply, %{state | last_crc: crc}}
    end

    defp configure_dithering(_cap, nil),
      do: nil

    defp configure_dithering(cap, dithering),
      do: :ok = RpiFbCapture.set_dithering(cap, dithering)

    defp get_display(display_config) when is_list(display_config),
      do: OLED.Display.Server.start_link(display_config)

    defp get_display(display_name) when is_atom(display_name),
      do: {:ok, display_name}

    defp get_display(_),
      do: {:error, :display_config}

    defp vp_supervisor(viewport) do
      [supervisor_pid | _] =
        viewport
        |> Process.info()
        |> get_in([:dictionary, :"$ancestors"])

      supervisor_pid
    end
  end
end
