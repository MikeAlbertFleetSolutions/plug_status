defmodule PlugStatus.Mixfile do
  use Mix.Project

  @version "0.1.0"
  @github_url "https://github.com/MikeAlbertFleetSolutions/plug_status"
  @description """
  A plug for responding to status requests.
  """

  def project do
    [
      app: :plug_status,
      version: @version,
      elixir: "~> 1.0",
      deps: deps(),
      description: @description,
      name: "PlugStatus",
      source_url: @github_url,
      package: package()
    ]
  end

  def application do
    [applications: [:logger, :cowboy, :plug]]
  end

  defp deps do
    [
      {:cowboy, ">= 1.0.0"},
      {:plug, ">= 0.12.0"},
      {:poison, "~> 3.1"},
      {:earmark, "~> 1.2.2", only: :dev, runtime: false},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Brian Bathe"],
      licenses: ["MIT"],
      links: %{"GitHub" => @github_url}
    ]
  end
end
