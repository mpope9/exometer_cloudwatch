defmodule :exometer_report_cloudwatch_spec do
  use ESpec, async: true

  import :exometer_report_cloudwatch

  describe "exometer_init/1" do
    context "with direct configuration" do
      let :config, do: [
        host: "my.test.host",
        access_key_id: "AAABBBCCCDDD",
        secret_access_key: "1234567890ABCDEFGHIJK",
        region: "us-east1",
        namespace: "App/MyApplication",
        dimensions: [{"InstanceId", "i-1234567"}]
      ]

      subject do
        {:ok, result} = exometer_init(config())
        Map.to_list(result)
      end

      it do: should(have {:host, "my.test.host"})
      it do: should(have {:access_key_id, "AAABBBCCCDDD"})
      it do: should(have {:secret_access_key, "1234567890ABCDEFGHIJK"})
      it do: should(have {:region, "us-east1"})
      it do: should(have {:namespace, "App/MyApplication"})
      it do: should(have {:dimensions, [{"InstanceId", "i-1234567"}]})

      context "and default host" do
        subject do
          {:ok, result} =
            config()
            |> Keyword.drop([:host])
            |> exometer_init()

          Map.to_list(result)
        end

        it do: should(have {:host, "monitoring.us-east1.amazonaws.com"})
      end

      context "and default namespace" do
        subject do
          {:ok, result} =
            config()
            |> Keyword.drop([:namespace])
            |> exometer_init()

          Map.to_list(result)
        end

        it do: should(have {:namespace, "App/Exometer"})
      end

      context "with config in OS environment" do

      end
    end
  end

  describe "exometer_report/5" do

  end

  describe "unused callbacks" do
    it do: assert {:ok, :state} = exometer_subscribe(nil, nil, nil, nil, :state)
    it do: assert {:ok, :state} = exometer_unsubscribe(nil, nil, nil, :state)
    it do: assert {:ok, :state} = exometer_call(nil, nil, :state)
    it do: assert {:ok, :state} = exometer_cast(nil, :state)
    it do: assert {:ok, :state} = exometer_info(nil, :state)
    it do: assert {:ok, :state} = exometer_newentry(nil, :state)
    it do: assert {:ok, :state} = exometer_setopts(nil, nil, nil, :state)
    it do: assert :ignore = exometer_terminate(nil, :state)
  end
end
