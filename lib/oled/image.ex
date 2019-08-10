defmodule OLED.Image do
  @moduledoc false

  @default_threshold 125

  @type t :: %__MODULE__{
          width: integer(),
          height: integer(),
          data: list(list(boolean() | nil))
        }

  @type load_opts :: [
          threshold: integer()
        ]

  defstruct width: nil,
            height: nil,
            data: nil

  use Bitwise

  @spec load_binarized(path_to_file :: String.t(), opts :: load_opts()) ::
          {:ok, t()} | {:error, term()}
  def load_binarized(path_to_file, opts \\ []) do
    with charlist_path <- to_charlist(path_to_file),
         {:ok, img} <- :erl_img.load(charlist_path),
         {:pixmap, [pixmap]} <- {:pixmap, elem(img, 19)},
         {:ok, width, height, data} <- binarize_pixmap(pixmap, opts) do
      {:ok,
       %__MODULE__{
         width: width,
         height: height,
         data: data
       }}
    end
  end

  defp binarize_pixmap(
         {
           :erl_pixmap,
           _top,
           _left,
           width,
           height,
           _palette,
           :r16g16b16a16,
           _attr,
           pixels
         },
         opts
       ) do
    data =
      Enum.map(pixels, fn {_, line} ->
        line
        |> pixmap_line_rgba16_to_graya()
        |> binarize_graya_line(opts[:threshold] || @default_threshold)
      end)

    {:ok, width, height, data}
  end

  defp binarize_pixmap(
         {
           :erl_pixmap,
           _top,
           _left,
           width,
           height,
           _palette,
           :r16g16b16,
           _attr,
           pixels
         },
         opts
       ) do
    data =
      Enum.map(pixels, fn {_, line} ->
        line
        |> pixmap_line_rgb16_to_gray()
        |> binarize_gray_line(opts[:threshold] || @default_threshold)
      end)

    {:ok, width, height, data}
  end

  defp binarize_pixmap(
         {
           :erl_pixmap,
           _top,
           _left,
           width,
           height,
           _palette,
           :r8g8b8a8,
           _attr,
           pixels
         },
         opts
       ) do
    data =
      Enum.map(pixels, fn {_, line} ->
        line
        |> pixmap_line_rgba8_to_graya()
        |> binarize_graya_line(opts[:threshold] || @default_threshold)
      end)

    {:ok, width, height, data}
  end

  defp binarize_pixmap(
         {
           :erl_pixmap,
           _top,
           _left,
           width,
           height,
           _palette,
           :r8g8b8,
           _attr,
           pixels
         },
         opts
       ) do
    data =
      Enum.map(pixels, fn {_, line} ->
        line
        |> pixmap_line_rgb8_to_gray()
        |> binarize_gray_line(opts[:threshold] || @default_threshold)
      end)

    {:ok, width, height, data}
  end

  defp binarize_pixmap(
         {
           :erl_pixmap,
           _top,
           _left,
           width,
           height,
           _palette,
           :gray8a8,
           _attr,
           pixels
         },
         opts
       ) do
    data =
      Enum.map(pixels, fn {_, line} ->
        line
        |> binarize_graya_line(opts[:threshold] || @default_threshold)
      end)

    {:ok, width, height, data}
  end

  defp binarize_pixmap(
         {
           :erl_pixmap,
           _top,
           _left,
           width,
           height,
           _palette,
           :gray8,
           _attr,
           pixels
         },
         opts
       ) do
    data =
      Enum.map(pixels, fn {_, line} ->
        line
        |> binarize_gray_line(opts[:threshold] || @default_threshold)
      end)

    {:ok, width, height, data}
  end

  defp binarize_pixmap(_, _),
    do: {:error, :invalid_format}

  defp pixmap_line_rgb16_to_gray(line),
    do: pixmap_line_rgb16_to_gray(line, <<>>)

  defp pixmap_line_rgb16_to_gray(
         <<r::size(16), g::size(16), b::size(16), rest::binary>>,
         acc
       ) do
    gray = rgb_to_gray(r >>> 8, g >>> 8, b >>> 8)

    pixmap_line_rgb16_to_gray(rest, acc <> <<gray>>)
  end

  defp pixmap_line_rgb16_to_gray(<<>>, acc),
    do: acc

  defp pixmap_line_rgba16_to_graya(line),
    do: pixmap_line_rgba16_to_graya(line, <<>>)

  defp pixmap_line_rgba16_to_graya(
         <<r::size(16), g::size(16), b::size(16), a::size(16), rest::binary>>,
         acc
       ) do
    gray = rgb_to_gray(r >>> 8, g >>> 8, b >>> 8)
    alpha = a >>> 8

    pixmap_line_rgba16_to_graya(rest, acc <> <<gray, alpha>>)
  end

  defp pixmap_line_rgba16_to_graya(<<>>, acc),
    do: acc

  defp pixmap_line_rgb8_to_gray(line),
    do: pixmap_line_rgb8_to_gray(line, <<>>)

  defp pixmap_line_rgb8_to_gray(
         <<r::size(8), g::size(8), b::size(8), rest::binary>>,
         acc
       ) do
    gray = rgb_to_gray(r, g, b)

    pixmap_line_rgb8_to_gray(rest, acc <> <<gray>>)
  end

  defp pixmap_line_rgb8_to_gray(<<>>, acc),
    do: acc

  defp pixmap_line_rgba8_to_graya(line),
    do: pixmap_line_rgba8_to_graya(line, <<>>)

  defp pixmap_line_rgba8_to_graya(
         <<r::size(8), g::size(8), b::size(8), a::size(8), rest::binary>>,
         acc
       ) do
    gray = rgb_to_gray(r, g, b)

    pixmap_line_rgba8_to_graya(rest, acc <> <<gray, a>>)
  end

  defp pixmap_line_rgba8_to_graya(<<>>, acc),
    do: acc

  defp binarize_gray_line(line, threshold),
    do: binarize_gray_line(line, threshold, [])

  defp binarize_gray_line(
         <<g::size(8), rest::binary>>,
         threshold,
         acc
       ) do
    binarize_gray_line(rest, threshold, [g >= threshold | acc])
  end

  defp binarize_gray_line(<<>>, _threshold, acc),
    do: Enum.reverse(acc)

  defp binarize_graya_line(line, threshold),
    do: binarize_graya_line(line, threshold, [])

  defp binarize_graya_line(
         <<g::size(8), a::size(8), rest::binary>>,
         threshold,
         acc
       ) do
    value =
      cond do
        a > 0 ->
          g >= threshold

        true ->
          nil
      end

    binarize_graya_line(rest, threshold, [value | acc])
  end

  defp binarize_graya_line(<<>>, _threshold, acc),
    do: Enum.reverse(acc)

  defp rgb_to_gray(r, g, b) do
    value = trunc(0.3 * r + 0.6 * g + 0.11 * b)

    if value > 255 do
      255
    else
      value
    end
  end
end
