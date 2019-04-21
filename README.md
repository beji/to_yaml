# ToYaml

`ToYaml` is a simple module that converts a `map()` to an `iolist()` that will hopefully turn in to the expected [YAML](https://yaml.org/) output when printed as a string or written into a file.
`to_yaml/1` should serve as the main entry point here.

This allows you to write something like

```elixir
%{
  :apiVersion => "v1",
  :kind => "Service",
  :metadata => %{
    :name => "fancy-name"
  },
  :spec => %{
    :ports => [
      %{
        :port => 80,
        :targetPort => 3000
      }
    ],
    :selector => %{
      :app => "fancy-name"
    }
  }
}
```

and have it turned into

```yaml
apiVersion: v1
kind: Service
metadata:
  name: fancy-name
spec:
  ports:
    - port: 80
      targetPort: 3000
  selector:
    app: fancy-name
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `to_yaml` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:to_yaml, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/to_yaml](https://hexdocs.pm/to_yaml).
