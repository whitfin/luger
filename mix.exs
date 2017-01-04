defmodule Luger.Mixfile do
  use Mix.Project

  @url_docs "http://hexdocs.pm/luger"
  @url_github "https://github.com/zackehh/luger"

  def project do
    [
      app: :luger,
      name: "Luger",
      description: "Handy logging plug for Elixir with IP and status support",
      package: %{
        files: [
          "lib",
          "mix.exs",
          "LICENSE",
          "README.md"
        ],
        licenses: [ "MIT" ],
        links: %{
          "Docs" => @url_docs,
          "GitHub" => @url_github
        },
        maintainers: [ "Isaac Whitfield" ]
      },
      version: "1.0.0",
      elixir: "~> 1.2",
      deps: deps(),
      docs: [
        extras: [ "README.md" ],
        source_ref: "master",
        source_url: @url_github
      ],
      test_coverage: [
        tool: ExCoveralls
      ]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :pre_plug]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{ :pre_plug,    "~> 0.1" },
     { :excoveralls, "~> 0.5", optional: true, only: [ :dev, :test ] },
     { :plug,        "~> 1.2", optional: true, only: [ :dev, :test ] }]
  end
end
