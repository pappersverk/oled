defmodule OLED.MixProject do
  use Mix.Project

  @version "0.3.6"

  def project do
    [
      app: :oled,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      aliases: aliases(),
      description: description(),
      docs: docs(),
      package: package(),
      source_url: "https://github.com/pappersverk/oled",
      dialyzer: [
        flags: [:unmatched_returns, :error_handling, :race_conditions, :underspecs]
      ]
    ]
  end

  defp description do
    """
    OLED is a library to manage the monochrome OLED screen based on chip SSD1306.
    Implements a Scenic driver but also set of graphic primitves to work standalone.
    """
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    %{
      files: ["lib", "mix.exs", "README.md"],
      maintainers: [
        "Gabriel Roldan",
        "Phillipp Ohlandt"
      ],
      licenses: ["Apache License 2.0"],
      links: %{
        "GitHub" => "https://github.com/pappersverk/oled"
      }
    }
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: "https://github.com/pappersverk/oled",
      extras: [
        "README.md"
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:circuits_spi, "~> 1.3"},
      {:circuits_i2c, "~> 1.0.1"},
      {:circuits_gpio, "~> 1.0.1"},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:earmark, "~> 1.4", only: :dev, runtime: false},
      {:dialyxir, "1.2.0", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [docs: ["docs", &copy_images/1]]
  end

  defp copy_images(_) do
    File.cp_r!("images/", "doc/images/")
  end
end
