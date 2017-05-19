defmodule ExometerCloudwatch.Mixfile do
  use Mix.Project

  def project do
    [app: :exometer_cloudwatch,
     version: "0.2.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     test_coverage: [tool: ExCoveralls, test_task: "espec"],
     preferred_cli_env: [
       espec: :test,
       coveralls: :test,
       "coveralls.html": :test
     ],
     dialyzer: [
       #plt_add_apps: [:mix, :mnesia, :inets],
       #plt_add_deps: :transitive,
       #ignore_warnings: "dialyzer.ignore-warnings",
       flags: [
         # :unmatched_returns,
         # :underspecs,
         :error_handling,
         :race_conditions
       ]
     ],
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [extra_applications: []]
  end

  defp deps do
    [
      {:ex_aws,        "~> 1.1"},
      {:confex,        "~> 2.0"},
      {:lager,         "~> 3.4", override: true},
      {:hackney,       "~> 1.8", override: true},
      {:httpoison,     "~> 0.11.2"},
      {:exometer_core, "~> 1.4"},
      {:certifi, github: "hippware/erlang-certifi",
                 branch: "working",
                 manager: :rebar3,
                 override: true},

      {:credo,       "~> 0.7", only: [:dev, :test]},
      {:dialyxir,    "~> 0.5", only: [:dev, :test]},
      {:espec,       "~> 1.4", only: :test},
      {:excoveralls, "~> 0.6", only: :test}
    ]
  end
end
