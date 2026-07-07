defmodule WebSockex.Mixfile do
  use Mix.Project

  def project do
    [
      aliases: aliases(),
      app: :websockex,
      name: "WebSockex",
      version: "0.5.1",
      elixir: "~> 1.18",
      description: "An Elixir WebSocket client",
      source_url: "https://github.com/Azolo/websockex",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      deps: deps(),
      docs: docs()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger, :ssl, :crypto, :telemetry],
      mod: {WebSockex.Application, []}
    ]
  end

  defp aliases do
    [
      lint: [
        "compile --warnings-as-errors",
        "format --check-formatted",
        "credo --only warning"
      ]
    ]
  end

  defp deps do
    [
      {:telemetry, "~> 1.4"},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      {:cowboy, "~> 2.17", only: :test},
      {:plug_cowboy, "~> 2.9", only: :test},
      {:plug, "~> 1.20", only: :test},
      {:credo, "~> 1.7", only: :dev, runtime: false},
      {:stream_data, "~> 1.2", only: [:dev, :test]}
    ]
  end

  defp package do
    %{
      name: :websockex,
      licenses: ["MIT"],
      maintainers: ["Dominic Letz"],
      links: %{"GitHub" => "https://github.com/witchtails/websockex_wt"}
    }
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme"
    ]
  end
end
