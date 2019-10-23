if Code.ensure_loaded?(Scenic.ViewPort.Driver) and
     Code.ensure_loaded?(Scenic.Driver.Nerves.Rpi) and
     Code.ensure_loaded?(RpiFbCapture) do
  defmodule OLED.Scenic.Driver do
    use Scenic.ViewPort.Driver

    alias OLED.Display
    alias Scenic.ViewPort.Driver

    @impl true
    def init(viewport, size, config) do
      vp_supervisor = vp_supervisor(viewport)
      rpi_driver_config = {vp_supervisor, size, %{module: Scenic.Driver.Nerves.Rpi}}

      with {:ok, rpi_driver} <- Driver.start_link(rpi_driver_config),
           {:ok, display} <- get_display(config[:display]),
           {:ok, width, height} <- Display.Server.get_dimensions(display),
           {:ok, cap} <- RpiFbCapture.start_link(width: width, height: height, display: 0) do
        # Waiting for dithering on rpi_fb_capture :)
        # :ok = RpiFbCapture.set_dithering(cap, :sierra)

        send(self(), :capture)

        {:ok,
         %{
           viewport: viewport,
           display: display,
           cap: cap,
           rpi_driver: rpi_driver,
           last_crc: -1
         }}
      end
    end

    @impl true
    def handle_info(:capture, state) do
      {:ok, frame} = RpiFbCapture.capture(state.cap, :mono_column_scan)

      crc = :erlang.crc32(frame.data)

      if crc != state.last_crc do
        Display.Server.display_frame(state.display, frame.data, memory_mode: :vertical)
      end

      Process.send_after(self(), :capture, 50)
      {:noreply, %{state | last_crc: crc}}
    end

    defp get_display(display_config) when is_list(display_config),
      do: Display.Server.start_link(display_config)

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
