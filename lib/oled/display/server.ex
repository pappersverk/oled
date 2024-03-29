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

  @type display_frame_opts :: [
          memory_mode: :horizontal | :vertical | :page_addr
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
  def display_frame(server, data, opts \\ []),
    do: GenServer.call(server, {:display_frame, data, opts})

  @doc false
  def display_raw_frame(server, data, opts \\ []),
    do: GenServer.call(server, {:display_raw_frame, data, opts})

  @doc false
  def clear(server, pixel_state \\ :off),
    do: GenServer.call(server, {:clear, pixel_state})

  @doc false
  def put_buffer(server, data),
    do: GenServer.call(server, {:put_buffer, data})

  @doc false
  def get_buffer(server),
    do: GenServer.call(server, :get_buffer)

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
  def circle(server, x0, y0, r, opts),
    do: GenServer.call(server, {:circle, x0, y0, r, opts})

  @doc false
  def rect(server, x, y, width, height, opts),
    do: GenServer.call(server, {:rect, x, y, width, height, opts})

  @doc false
  def fill_rect(server, x, y, width, height, opts),
    do: GenServer.call(server, {:fill_rect, x, y, width, height, opts})

  @doc false
  def get_dimensions(server),
    do: GenServer.call(server, :get_dimensions)

  @doc false
  def handle_call(:display, _from, {impl, state}) do
    state
    |> impl.display()
    |> handle_response(impl, state)
  end

  @doc false
  def handle_call({:display_frame, data, opts}, _from, {impl, state}) do
    state
    |> impl.display_frame(data, opts)
    |> handle_response(impl, state)
  end

  @doc false
  def handle_call({:display_raw_frame, data, opts}, _from, {impl, state}) do
    state
    |> impl.display_raw_frame(data, opts)
    |> handle_response(impl, state)
  end

  def handle_call({:clear, pixel_state}, _from, {impl, state}) do
    state
    |> impl.clear_buffer(pixel_state)
    |> handle_response(impl, state)
  end

  def handle_call({:put_buffer, data}, _from, {impl, state}) do
    state
    |> impl.put_buffer(data)
    |> handle_response(impl, state)
  end

  def handle_call(:get_buffer, _from, {impl, state}) do
    res = impl.get_buffer(state)

    {:reply, res, {impl, state}}
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

  def handle_call({:circle, x0, y0, r, opts}, _from, {impl, state}) do
    state
    |> impl.circle(x0, y0, r, opts)
    |> handle_response(impl, state)
  end

  def handle_call({:fill_rect, x, y, width, height, opts}, _from, {impl, state}) do
    state
    |> impl.fill_rect(x, y, width, height, opts)
    |> handle_response(impl, state)
  end

  def handle_call(:get_dimensions, _from, {impl, state}) do
    res = impl.get_dimensions(state)

    {:reply, res, {impl, state}}
  end

  defp handle_response({:error, _} = error, impl, old_state),
    do: {:reply, error, {impl, old_state}}

  defp handle_response(state, impl, _old_state),
    do: {:reply, :ok, {impl, state}}
end
