defmodule HTTPill.Mixfile do
  use Mix.Project

  def project do
    [
      app: :httpill,
      version: "0.1.0",
      elixir: "~> 1.5",
      description: "HTTP requests for sick people!",
      name: "HTTPill",
      source_url: "https://github.com/kelvinst/httpill",
      start_permanent: Mix.env == :prod,

      package: [
        name: :httpill,
        files: ["lib", "mix.exs", "README*", "LICENSE*"],
        maintainers: ["Kelvin Stinghen"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/kelginst/httpill"}
      ],

      deps: deps()
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
			{:hackney, "~> 1.8"},
      {:poison, "~> 3.1"},

      {:exjsx, "~> 3.1", only: :test},
      {:httparrot, "~> 0.5", only: :test},
      {:meck, "~> 0.8.2", only: :test},

      {:ex_doc, ">= 0.0.0", only: :dev},
    ]
  end
end
