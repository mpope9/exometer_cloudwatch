%% -------------------------------------------------------------------
%%
%% Copyright (c) 2016 Hippware Inc. All Rights Reserved.
%%
%%   This Source Code Form is subject to the terms of the Mozilla Public
%%   License, v. 2.0. If a copy of the MPL was not distributed with this
%%   file, You can obtain one at http://mozilla.org/MPL/2.0/.
%%
%%  Required Parameters:
%%
%%  access_key_id - An access key ID for an AWS user with appropriate
%%                  put_metrics permissions
%%  secret_access_key - The secret access key for the same user
%%  region - The region to which to report metrics
%%  dimensions - At least one dimention pair ([{"Key", "Value"}]) on which to
%%               report metrics
%%
%%  Optional Parameters:
%%
%%  host - Overrides the default CloudWatch host
%%  namespace - Specify a namespace for reported metrics (default is
%%              "App/Exometer")
%%
%%
%%  Example config:
%%
%%  {exometer,
%%    {reporters, [
%%      {exometer_report_cloudwatch, [
%%        {access_key_id,     "AAABBBCCCDDD},
%%        {secret_access_key, "1234567890ABCDEFGHIJK"},
%%        {region,            "us-east-1"},
%%        {namespace,         "App/MyApplication"},
%%        {dimensions,        [{"InstanceId", "i-1234567"}]}
%%      ]}
%%    ]}
%%  ]
%%
%% -------------------------------------------------------------------

-module(exometer_report_cloudwatch).
-behaviour(exometer_report).

%% exometer_report callbacks
-export(
   [
    exometer_init/1,
    exometer_info/2,
    exometer_cast/2,
    exometer_call/3,
    exometer_report/5,
    exometer_subscribe/5,
    exometer_unsubscribe/4,
    exometer_newentry/2,
    exometer_setopts/4,
    exometer_terminate/2
   ]).

-import(exometer_util, [get_opt/3, get_opt/2]).

-define(DEFAULT_NS, "App/Exometer").

-define(aws_auth, 'Elixir.ExAws.Auth').

-record(state, {
          host              :: string(),
          access_key_id     :: string(),
          secret_access_key :: string(),
          region            :: string(),
          namespace         :: string(),
          dimensions        :: [{string(), string()}]
         }).

%%%===================================================================
%%% exometer_report callbacks
%%%===================================================================

exometer_init(Opts) ->
    Region = get_opt(region, Opts),
    DefaultHost = "monitoring." ++ Region ++ ".amazonaws.com",
    application:ensure_all_started(hackney),
    State = #state{
               host              = get_opt(host, Opts, DefaultHost),
               access_key_id     = get_opt(access_key_id, Opts),
               secret_access_key = get_opt(secret_access_key, Opts),
               region            = Region,
               namespace         = get_opt(namespace, Opts, ?DEFAULT_NS),
               dimensions        = get_opt(dimensions, Opts, [])
              },
    {ok, State}.

exometer_report(Probe, DataPoint, _Extra, Value,
                State = #state{host = Host,
                               namespace = Namespace,
                               dimensions = Dimensions}) ->
    Params =
    [{"Action", "PutMetricData"},
     {"Version", "2010-08-01"},
     {"Namespace", Namespace},
     {"MetricData.member.1.MetricName", name(Probe, DataPoint)},
     {"MetricData.member.1.Value", value(Value)}
     | make_dimensions(Dimensions)],
    send_metric(make_url_and_headers(Host, Params, State)),
    {ok, State}.

exometer_subscribe(_Metric, _DataPoint, _Extra, _Interval, State) ->
    {ok, State}.

exometer_unsubscribe(_Metric, _DataPoint, _Extra, State) ->
    {ok, State}.

exometer_call(_Unknown, _From, State) ->
    {ok, State}.

exometer_cast(_Unknown, State) ->
    {ok, State}.

exometer_info(_Unknown, State) ->
    {ok, State}.

exometer_newentry(_Entry, State) ->
    {ok, State}.

exometer_setopts(_Metric, _Options, _Status, State) ->
    {ok, State}.

exometer_terminate(_, _) ->
    ignore.

%%%===================================================================
%%% private helpers
%%%===================================================================

make_url_and_headers(Host, Params, State) ->
    URL = ["http://", Host, "/?" | params(Params)],
    {ok, Headers} = ?aws_auth:headers(get, iolist_to_binary(URL),
                                      monitoring, make_aws_config(State),
                                      [], []),
    {lists:flatten(URL), to_string_headers(Headers)}.

to_string_headers(Headers) ->
    lists:map(fun({A, B}) -> {binary_to_list(A), binary_to_list(B)} end,
              Headers).

params([Param|Tail]) ->
    [param(Param) |
     lists:map(fun(P) -> ["&", param(P)] end, Tail)].

param({Key, Val}) ->
    [Key, "=", Val].

make_aws_config(#state{access_key_id = AccessKey,
                       secret_access_key = SecretKey,
                       region = Region}) ->
    #{access_key_id => iolist_to_binary(AccessKey),
      secret_access_key => iolist_to_binary(SecretKey),
      region => iolist_to_binary(Region)}.

make_dimensions(Dimensions) ->
    {Result, _} = lists:mapfoldl(fun make_dimension/2, 1, Dimensions),
    lists:flatten(Result).

make_dimension({Key, Value}, Count) ->
    Prefix = ["MetricData.member.1.Dimensions.member.",
              integer_to_list(Count), "."],
    {[{[Prefix, "Name"], Key},
      {[Prefix, "Value"], Value}],
     Count +1}.

datapoint(V) when is_integer(V) -> integer_to_list(V);
datapoint(V) when is_atom(V) -> atom_to_list(V).

%% Add value, int or float, converted to list
value(V) when is_integer(V) -> integer_to_list(V);
value(V) when is_float(V)   -> float_to_list(V);
value(_) -> 0.

send_metric({URL, Headers}) ->
    Method = get,
    Url = URL,
    Headers = Headers,
    Payload = <<>>,
    Options = [{pool, default}],
    {ok, StatusCode, RespHeaders, ClientRef} = hackney:request( Method, Url, Headers, Payload, Options).

name(Probe, DataPoint) ->
    [[[metric_elem_to_list(I), $.] || I <- Probe], datapoint(DataPoint)].

metric_elem_to_list(V) when is_atom(V) -> atom_to_list(V);
metric_elem_to_list(V) when is_binary(V) -> binary_to_list(V);
metric_elem_to_list(V) when is_integer(V) -> integer_to_list(V);
metric_elem_to_list(V) when is_list(V) -> V.
