defmodule Vuelos.MixProject do
  use Mix.Project

  def project do
    [
      app: :vuelos,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      test_pattern: "*Test.exs",
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Vuelos.Aplicacion, []}
    ]
  end

  defp deps do
    []
  end
end
