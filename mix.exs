defmodule JsonRpcToolkit.MixProject do
  use Mix.Project

  def project do
    [
      app: :json_rpc_toolkit,
      version: "0.9.3",
      name: "json_rpc_toolkit",
      description: "A transport agnostic JSON-RPC library with support for Phoenix",
      elixir: "~> 1.8",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      dialyzer: [
        plt_add_deps: :project
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE*"],
      maintainers: ["Versus Systems", "Alex Peachey"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/versus-systems/json_rpc_toolkit"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.1"},
      {:plug, "~> 1.6", optional: true},
      {:phoenix, "~> 1.3", optional: true},
      {:phoenix_pubsub, "~> 1.0", optional: true},
      {:dialyxir, "1.0.0-rc.2", runtime: false, only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
