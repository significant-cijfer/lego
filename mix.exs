defmodule Lego.MixProject do
  use Mix.Project

  def project do
    [
      app: :lego,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Lego.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:typed_struct, "~> 0.3.0"},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
    ]
  end
end
