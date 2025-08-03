defmodule AshCharts.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/yourusername/ash_charts"

  def project do
    [
      app: :ash_charts,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "AshCharts",
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # Core dependencies
      {:ash, "~> 3.0"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix, "~> 1.7"},
      {:jason, "~> 1.2"},
      
      # Dev/test dependencies
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    "A reusable chart library for Ash Framework applications with Phoenix LiveView integration."
  end

  defp package do
    [
      name: "ash_charts",
      files: ~w(lib priv mix.exs README* LICENSE* CHANGELOG*),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      },
      maintainers: ["Your Name"]
    ]
  end

  defp docs do
    [
      main: "AshCharts",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end
end
