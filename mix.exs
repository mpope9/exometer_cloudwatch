defmodule ExometerCloudwatchWithPooling.Mixfile do
  use Mix.Project

  def project do
    [app: :exometer_cloudwatch_with_pooling,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
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
      {:ex_aws, "~> 1.1"},
      {:exometer_core, github: "Feuerlabs/exometer_core", branch: "master"},
      {:meck, github: "eproxus/meck", tag: "0.8.2", override: true, runtime: false},
      {:edown, github: "uwiger/edown", tag: "0.7", override: true, runtime: false},
      {:hackney, github: "benoitc/hackney", tag: "1.11.0", override: true, runtime: false}
    ]
  end
end
