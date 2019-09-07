defmodule OLED.Display do
  @moduledoc """
  Defines a display module

  When used, the displaly expects an `:app` as option.
  The `:app` should be the app that has the configuration.

  Example:

      defmodule MyApp.MyDisplay do
        use OLED.Display, app: :my_app
      end

  Could be configured with:
      config :my_app, MyApp.MyDisplay,
        driver: :ssd1306,
        spi_dev: "spidev0.0",
        width: 128,
        height: 64,
        rst_pin: 25,
        dc_pin: 24

  ## Configuration:

    * `:driver` - For now only `:ssd1306` is available

    * `:spi_dev` - SPI device

    * `:width` - Display width

    * `:height` - Display height

    * `:rst_pin` - GPIO for RESET pin

    * `:dc_pin` - GPIO for DC pin
  """

  alias OLED.Display.Server

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts, moduledoc: @moduledoc] do
      @moduledoc moduledoc
                 |> String.replace(~r/MyApp\.MyDisplay/, Enum.join(Module.split(__MODULE__), "."))
                 |> String.replace(~r/:my_app/, Atom.to_string(Keyword.fetch!(opts, :app)))

      @app Keyword.fetch!(opts, :app)
      @me __MODULE__

      @behaviour OLED.Display

      def module_config(),
        do: Application.get_env(@app, @me, [])

      def start_link(config \\ []) do
        module_config()
        |> Keyword.merge(config)
        |> Server.start_link(name: @me)
      end

      spec = [
        id: opts[:id] || @me,
        start: Macro.escape(opts[:start]) || quote(do: {@me, :start_link, [opts]}),
        restart: opts[:restart] || :permanent,
        type: :worker
      ]

      @doc false
      @spec child_spec(Keyword.t()) :: Supervisor.child_spec()
      def child_spec(opts) do
        %{unquote_splicing(spec)}
      end

      defoverridable child_spec: 1

      def display(),
        do: Server.display(@me)

      def display_frame(data, opts \\ []),
        do: Server.display_frame(@me, data, opts)

      def clear(),
        do: Server.clear(@me)

      def clear(pixel_state),
        do: Server.clear(@me, pixel_state)

      def put_pixel(x, y, opts \\ []),
        do: Server.put_pixel(@me, x, y, opts)

      def line(x1, y1, x2, y2, opts \\ []),
        do: Server.line(@me, x1, y1, x2, y2, opts)

      def line_h(x, y, width, opts \\ []),
        do: Server.line_h(@me, x, y, width, opts)

      def line_v(x, y, height, opts \\ []),
        do: Server.line_v(@me, x, y, height, opts)

      def image(path, x, y, opts \\ []),
        do: Server.image(@me, path, x, y, opts)

      def rect(x, y, width, height, opts \\ []),
        do: Server.rect(@me, x, y, width, height, opts)
    end
  end

  @doc """
  Transfer the display buffer to the screen. You MUST call display() after
  drawing commands to make them visible on screen.
  """
  @callback display() :: :ok

  @doc """
  Transfer a data frame to the display buffer.
  """
  @callback display_frame(data :: binary(), opts :: Server.display_frame_opts()) :: :ok

  @doc """
  Clear the buffer.
  """
  @callback clear() :: :ok

  @doc """
  Clear the buffer putting all the pixels on certain state.
  """
  @callback clear(pixel_state :: Server.pixel_state()) :: :ok

  @doc """
  Put a pixel on the buffer. The pixel can be on or off and be drawed in xor mode (if the pixel is already on is turned off).
  """
  @callback put_pixel(
              x :: integer(),
              y :: integer(),
              opts :: Server.pixel_opts()
            ) ::
              :ok

  @doc """
  Draw a line.
  """
  @callback line(
              x1 :: integer(),
              y1 :: integer(),
              x2 :: integer(),
              y2 :: integer(),
              opts :: Server.pixel_opts()
            ) :: :ok

  @doc """
  Draw an horizontal line (speed optimized).
  """
  @callback line_h(
              x :: integer(),
              y :: integer(),
              width :: integer(),
              opts :: Server.pixel_opts()
            ) :: :ok

  @doc """
  Draw a vertical line (speed optimized).
  """
  @callback line_v(
              x :: integer(),
              y :: integer(),
              height :: integer(),
              opts :: Server.pixel_opts()
            ) :: :ok

  @doc """
  Draw a rect
  """
  @callback rect(
              x :: integer(),
              y :: integer(),
              width :: integer(),
              height :: integer(),
              opts :: Server.pixel_opts()
            ) :: :ok

  @doc """
  Draw an image from a file.
  The image can be an PNG format with alpha channel.
  """
  @callback image(
              image_path :: String.t(),
              x :: integer(),
              y :: integer(),
              opts :: Server.image_opts()
            ) :: :ok | {:error, term()}
end
