defmodule OLED.Display.Server do
  @moduledoc """
  Display server
  """

  alias OLED.Display.Impl

  @typedoc """
  Pixel state

  `:on` - Pixel High in normal mode
  `:off` - Pixel Low in normal mode
  """

  @type pixel_state :: :on | :off

  @typedoc """
  Pixel options

  `mode` - Can be `:normal` or `:xor`
  `state` - Pixel state
  """
  @type pixel_opts :: [
          state: pixel_state(),
          mode: :normal | :xor
        ]

  @typedoc """
  Image options

  `mode` - Can be `:normal` or `:xor`
  `threshold` - Level from 0 to 255 used to determine when a pixel is considered High or Low
  """
  @type image_opts :: [
          threshold: integer(),
          mode: :normal | :xor
        ]

  @doc false
  def start_link(config, opts \\ []) do
    GenServer.start_link(__MODULE__, config, opts)
  end

  @doc false
  def init(config),
    do: Impl.init(config)

  @doc false
  def display(server),
    do: GenServer.call(server, :display)

  @doc false
  def clear(server, pixel_state \\ :off),
    do: GenServer.call(server, {:clear, pixel_state})

  @doc false
  def put_pixel(server, x, y, opts \\ []),
    do: GenServer.call(server, {:put_pixel, x, y, opts})

  @doc false
  def line(server, x1, y1, x2, y2, opts \\ []),
    do: GenServer.call(server, {:line, x1, y1, x2, y2, opts})

  @doc false
  def line_h(server, x, y, width, opts \\ []),
    do: GenServer.call(server, {:line_h, x, y, width, opts})

  @doc false
  def line_v(server, x, y, height, opts \\ []),
    do: GenServer.call(server, {:line_v, x, y, height, opts})

  @doc false
  def image(server, path, x, y, opts \\ []),
    do: GenServer.call(server, {:image, path, x, y, opts})

  @doc false
  def rect(server, x, y, width, height, opts),
    do: GenServer.call(server, {:rect, x, y, width, height, opts})

  @doc false
  def handle_call(:display, _from, {impl, state}) do
    state
    |> impl.display()
    |> handle_response(impl, state)
  end

  def handle_call({:clear, pixel_state}, _from, {impl, state}) do
    state
    |> impl.clear_buffer(pixel_state)
    |> handle_response(impl, state)
  end

  def handle_call({:put_pixel, x, y, opts}, _from, {impl, state}) do
    state
    |> impl.put_pixel(x, y, opts)
    |> handle_response(impl, state)
  end

  def handle_call({:line, x1, y1, x2, y2, opts}, _from, {impl, state}) do
    state
    |> impl.line(x1, y1, x2, y2, opts)
    |> handle_response(impl, state)
  end

  def handle_call({:line_h, x, y, width, opts}, _from, {impl, state}) do
    state
    |> impl.line_h(x, y, width, opts)
    |> handle_response(impl, state)
  end

  def handle_call({:line_v, x, y, height, opts}, _from, {impl, state}) do
    state
    |> impl.line_v(x, y, height, opts)
    |> handle_response(impl, state)
  end

  def handle_call({:rect, x, y, width, height, opts}, _from, {impl, state}) do
    state
    |> impl.rect(x, y, width, height, opts)
    |> handle_response(impl, state)
  end

  def handle_call({:image, path, x, y, opts}, _from, {impl, state}) do
    state
    |> impl.image(path, x, y, opts)
    |> handle_response(impl, state)
  end

  defp handle_response({:error, _} = error, impl, old_state),
    do: {:reply, error, {impl, old_state}}

  defp handle_response(state, impl, _old_state),
    do: {:reply, :ok, {impl, state}}
end
