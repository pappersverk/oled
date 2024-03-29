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
        width: 128,
        height: 64,
        driver: :ssd1306,
        type: :spi,
        device: "spidev0.0",
        rst_pin: 25,
        dc_pin: 24

  ## Configuration:

    * `:driver` - For now only `:ssd1306` is available

    * `:type` - Type of connection: (i.e.: `:spi`, `:i2c`)

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

      def display_raw_frame(data, opts \\ []),
        do: Server.display_raw_frame(@me, data, opts)

      def clear(),
        do: Server.clear(@me)

      def clear(pixel_state),
        do: Server.clear(@me, pixel_state)

      def put_buffer(data),
        do: Server.put_buffer(@me, data)

      def get_buffer(),
          do: Server.get_buffer(@me)

      def put_pixel(x, y, opts \\ []),
        do: Server.put_pixel(@me, x, y, opts)

      def line(x1, y1, x2, y2, opts \\ []),
        do: Server.line(@me, x1, y1, x2, y2, opts)

      def line_h(x, y, width, opts \\ []),
        do: Server.line_h(@me, x, y, width, opts)

      def line_v(x, y, height, opts \\ []),
        do: Server.line_v(@me, x, y, height, opts)

      def rect(x, y, width, height, opts \\ []),
        do: Server.rect(@me, x, y, width, height, opts)

      def circle(x0, y0, r, opts \\ []),
        do: Server.circle(@me, x0, y0, r, opts)

      def fill_rect(x, y, width, height, opts \\ []),
        do: Server.fill_rect(@me, x, y, width, height, opts)

      def get_dimensions(),
        do: Server.get_dimensions(@me)
    end
  end

  @doc """
  Transfer the display buffer to the screen. You MUST call display() after
  drawing commands to make them visible on screen.
  """
  @callback display() :: :ok

  @doc """
  Transfer a data frame to the screen. The data frame format is equal to the display buffer
  that gets altered via the drawing commands.

  Calling this function transfers the data frame directly to the screen and does not alter the display buffer.
  """
  @callback display_frame(data :: binary(), opts :: Server.display_frame_opts()) :: :ok

  @doc """
  Transfer a raw data frame to the screen.

  A raw data frame is in a different format than the display buffer.
  To transform a display buffer to a raw data frame, `OLED.Display.Impl.SSD1306.translate_buffer/3` can be used.
  """
  @callback display_raw_frame(data :: binary(), opts :: Server.display_frame_opts()) :: :ok

  @doc """
  Clear the buffer.
  """
  @callback clear() :: :ok

  @doc """
  Clear the buffer putting all the pixels on certain state.
  """
  @callback clear(pixel_state :: Server.pixel_state()) :: :ok

  @doc """
  Override the current buffer which is the internal data structure that is sent to the screen with `c:display/0`.

  A possible use-case is to draw some content, get the buffer via `c:get_buffer/0`
  and set it again at a later time to save calls to the draw functions.
  """
  @callback put_buffer(data :: binary()) :: :ok | {:error, term()}

  @doc """
  Get the current buffer which is the internal data structure that is changed by the draw methods
  and sent to the screen with `c:display/0`.
  """
  @callback get_buffer() :: {:ok, binary()}


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
  Draw a circle

  Origin `(x0, y0)` with radius `r`.
  """
  @callback circle(
              x0 :: integer(),
              y0 :: integer(),
              r :: integer(),
              opts :: Server.pixel_opts()
            ) :: :ok

  @doc """
  Draw a filled rect
  """
  @callback fill_rect(
              x :: integer(),
              y :: integer(),
              width :: integer(),
              height :: integer(),
              opts :: Server.pixel_opts()
            ) :: :ok

  @doc """
  Get display dimensions
  """
  @callback get_dimensions() ::
              {
                :ok,
                width :: integer(),
                height :: integer()
              }
              | {:error, term()}
end
