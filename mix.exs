defmodule PinboardDeclutter.MixProject do
  use Mix.Project

  def project do
    [
      app: :pinboard_declutter,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.4"},
      {:jason, "~> 1.1"},
      {:floki, "~> 0.1"},
      {:opq, "~> 3.1"},
      {:progress_bar, "> 0.0.0"}
    ]
  end

  defp escript do
    [
      main_module: PinboardDeclutter
    ]
  end
end
