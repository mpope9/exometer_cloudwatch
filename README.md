# ExometerCloudwatch

Basically the same as the forked repo, but using hackney instead of httpc.  Alows for connection pooling.

Credit for the idea to: [IRog](https://github.com/IRog/)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `exometer_cloudwatch` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:exometer_cloudwatch, "~> 0.1.0"}]
    end
    ```

  2. Ensure `exometer_cloudwatch` is started before your application:

    ```elixir
    def application do
      [applications: [:exometer_cloudwatch]]
    end
    ```

