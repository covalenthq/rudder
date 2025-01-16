defmodule Refiner.MixProject do
  use Mix.Project

  def project do
    [
      app: :refiner,
      version: "0.5.5",
      elixir: "~> 1.17.1",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls, export: "cov"],
      preferred_cli_env: [
        coveralls: :docker,
        "coveralls.detail": :docker,
        "coveralls.post": :docker,
        "coveralls.html": :docker
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      extra_applications: [:logger_file_backend, :runtime_tools, :poison, :avrora],
      mod: {Refiner.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # system exec
      {:poison, "~> 6.0"},
      {:distillery, "~> 2.0"},

      # frameworks
      {:broadway, "~> 1.0", override: true},
      {:off_broadway_redis, "~> 0.4.3"},
      {:phoenix, "~> 1.4.9"},
      {:phoenix_pubsub, "~> 1.1"},
      {:gettext, "~> 0.11"},
      {:plug_cowboy, "~> 2.0"},
      {:ranch, "~> 2.1.0",
       [env: :prod, hex: "ranch", repo: "hexpm", optional: false, override: true]},

      # eth parsing and encoding
      {:abi,
       github: "tsutsu/ethereum_abi",
       branch: "feature-parse-events-from-abi-specifications",
       override: true},
      {:ex_secp256k1, "0.7.4", override: true},
      {:ex_keccak, "~> 0.7.1", override: true},
      {:mnemonic, "~> 0.3"},
      {:ex_rlp, "~> 0.6.0", override: true},
      {:jason, "~> 1.3"},

      # architecture
      {:confex, "~> 3.3"},
      {:poolboy, "~> 1.5"},

      # networking
      {:certifi, "~> 2.9", override: true},
      {:cors_plug, "~> 3.0"},
      {:finch, "~> 0.19.0"},
      {:downstream, "~> 1.0"},
      {:websockex, "~> 0.4.3"},
      {:multipart, "~> 0.4.0"},

      # static code analysis
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:credo, "~> 1.7.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: [:test, :docker], runtime: false},

      # avro tools
      {:avrora, "~> 0.21"},

      # logging
      {:logger_file_backend, "~> 0.0.12"},
      {:etfs, "~> 0.2.0"},

      # tracing metrics
      {:telemetry, "~> 1.3.0", override: true},
      {:telemetry_metrics, "~> 0.3.0"},
      {:telemetry_metrics_prometheus, "~> 0.3.1"},
      {:telemetry_metrics_prometheus_core, "~>0.2.2"},

      # utils
      {:briefly, "~> 0.5.0"},
      {:rustler, ">= 0.0.0", optional: true},

      # Tesla for multipart
      {:tesla, "~> 1.12"},
      {:hackney, "~> 1.17"}

      # Unused
      # {:erlexec, "~> 2.0"},
      # {:etfs, path: "/Users/sudeep/repos/experiment/etfs"}
      # {:telemetry_metrics_prometheus, "~> 1.1"}
    ]
  end
end
