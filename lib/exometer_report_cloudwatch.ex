# -------------------------------------------------------------------
#
# Copyright (c) 2016 Hippware Inc. All Rights Reserved.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# -------------------------------------------------------------------
defmodule :exometer_report_cloudwatch do
  @moduledoc """
  Exometer reporter for Amazon CloudWatch

  Required Parameters:

    access_key_id - An access key ID for an AWS user with appropriate
                    put_metrics permissions
    secret_access_key - The secret access key for the same user
    region - The region to which to report metrics
    dimensions - At least one dimention pair ([{"Key", "Value"}]) on which to
                 report metrics

  Optional Parameters:

    host - Overrides the default CloudWatch host
    namespace - Specify a namespace for reported metrics (default is
                "App/Exometer")

  Example config:

    %% Erlang
    {exometer,
      {report, [
        {reporters, [
          {exometer_report_cloudwatch, [
            {access_key_id,     "AAABBBCCCDDD},
            {secret_access_key, "1234567890ABCDEFGHIJK"},
            {region,            "us-east-1"},
            {namespace,         "App/MyApplication"},
            {dimensions,        [{"InstanceId", "i-1234567"}]}
          ]}
        ]}
      ]}
    }

    # Elixir
    config :exometer,
      report: [
        reporters: [
          exometer_report_cloudwatch: [
            access_key_id:     "AAABBBCCCDDD",
            secret_access_key: "1234567890ABCDEFGHIJK",
            region:            "us-east1",
            namespace:         "App/MyApplication",
            dimensions:        [{"InstanceId", "i-1234567"}]
          ]
        ]
      ]
  """

  import :exometer_util, only: [get_opt: 2, get_opt: 3]

  alias ExAws.Auth

  @behaviour :exometer_report

  defmodule State do
    @moduledoc false
    defstruct [
      :host,
      :access_key_id,
      :secret_access_key,
      :region,
      :namespace,
      :dimensions
    ]
  end

  alias __MODULE__.State

  @default_ns "App/Exometer"

  # ===================================================================
  # exometer_report callbacks
  # ===================================================================

  def exometer_init(opts) do
    opts = Confex.process_env(opts)
    region = get_opt(:region, opts)
    default_host = "monitoring.#{ region }.amazonaws.com"
    {:ok, %State{
        host:              get_opt(:host, opts, default_host),
        access_key_id:     get_opt(:access_key_id, opts),
        secret_access_key: get_opt(:secret_access_key, opts),
        region:            region,
        namespace:         get_opt(:namespace, opts, @default_ns),
        dimensions:        get_opt(:dimensions, opts, [])
     }
    }
  end

  def exometer_report(probe, data_point, _extra, value, state) do
    params = [
      {"Action", "PutMetricData"},
      {"Version", "2010-08-01"},
      {"Namespace", state.namespace},
      {"MetricData.member.1.MetricName", name(probe, data_point)},
      {"MetricData.member.1.Value", value(value)}
      | make_dimensions(state.dimensions)
    ]

    state.host
    |> make_url_and_headers(params, state)
    |> send_metric()

    {:ok, state}
  end

  def exometer_subscribe(_metric, _data_point, _extra, _interval, state) do
    {:ok, state}
  end

  def exometer_unsubscribe(_metric, _data_point, _extra, state) do
    {:ok, state}
  end

  def exometer_call(_unknown, _from, state) do
    {:ok, state}
  end

  def exometer_cast(_unknown, state) do
    {:ok, state}
  end

  def exometer_info(_unknown, state) do
    {:ok, state}
  end

  def exometer_newentry(_entry, state) do
    {:ok, state}
  end

  def exometer_setopts(_metric, _options, _status, state) do
    {:ok, state}
  end

  def exometer_terminate(_, _) do
    :ignore
  end

  # ===================================================================
  # private helpers
  # ===================================================================

  defp name(probe, data_point) do
    [Enum.join(probe, "."), to_string(data_point)]
  end

  defp make_url_and_headers(host, params, state) do
    url = "http://#{ host }/?#{ params(params) }"
    {:ok, headers} =
      Auth.headers(:get, url, :monitoring, make_aws_config(state), [], [])
    {url, headers}
  end

  defp params(params) do
    params
    |> Enum.map(fn {k, v} -> "#{ k }=#{ v }" end)
    |> Enum.join("&")
  end

  defp make_aws_config(state) do
    Map.take(state, [:access_key_id, :secret_access_key, :region])
  end

  defp make_dimensions(dimensions) do
    {result, _} = Enum.map_reduce(dimensions, 1, &make_dimension/2)
    result
  end

  defp make_dimension({key, value}, count) do
    prefix = "MetricData.member.1.Dimensions.member.#{ count }"
    {[{"#{ prefix }.Name", key}, {"#{ prefix }.Value", value}], count + 1}
  end

  # Add value, int or float, converted to list
  defp value(v) when is_integer(v), do: to_string(v)
  defp value(v) when is_float(v),   do: to_string(v)
  defp value(_), do: 0

  defp send_metric({url, headers}),
    do: HTTPoison.get(url, headers, hackney: [pool: :exometer_cloudwatch])
end
