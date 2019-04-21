defmodule ToYaml do
  @moduledoc """
  `ToYaml` is a simple module that converts a `map()` to an `iolist()` that will turn in to the expected [YAML](https://yaml.org/) output when printed as a string or written into a file.
  This does not aim to contain a full spec implementation but a subset that should be enough for use cases like k8s or docker-compose.
  `to_yaml/1` should serve as the main entry point here.

  This allows you to write something like
  ```
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
  ```
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
  """

  @spacer Application.get_env(:to_yaml, :spacer)
  @spacerwidth Application.get_env(:to_yaml, :spacerwidth)

  @doc """
  Takes a given map and tries to turn it into an IO List based YAML representation of itself.
  This is actually an alias of `to_yaml/2` with the level parameter set to 0.

  ## Examples
    iex> ToYaml.to_yaml(%{"hello" => "world"})
    [["", "hello", ":", [" ", "world", "\\n"]]]

    iex> ToYaml.to_yaml(%{:hello => "world"})
    [["", "hello", ":", [" ", "world", "\\n"]]]
  """

  @spec to_yaml(map()) :: iolist()
  def to_yaml(input) when is_map(input), do: to_yaml(0, input)

  @doc """
  Takes a given map and tries to turn it into an IO List based YAML representation of itself.
  The level parameter is used to control the indentation of the YAML output with the help of `indent_level/1`

  ## Examples
    iex> ToYaml.to_yaml(0, %{"hello" => "world"})
    [["", "hello", ":", [" ", "world", "\\n"]]]

    iex> ToYaml.to_yaml(1, %{:hello => "world"})
    [["  ", "hello", ":", [" ", "world", "\\n"]]]
  """
  @spec to_yaml(number(), map()) :: iolist()
  def to_yaml(level, input) when is_number(level) and is_map(input) do
    input
    |> Enum.map(fn {key, value} ->
      [indent_level(level), to_key(key), ":", to_value(level, value)]
    end)
  end

  # TODO: The given keys might contain spaces or ':' characters, both aren't valid in this context I think
  @doc """
  Turns a map key into a YAML key. This currently only handles `String.t()` or `atom()` as the given input types as they are the only ones valid for yaml.
  This currently doesn't do any kind of input validation besides basic type matching.

  ## Examples
    iex> ToYaml.to_key("test")
    "test"

    iex> ToYaml.to_key(:test)
    "test"
  """
  @spec to_key(String.t() | atom()) :: String.t()
  def to_key(key) when is_atom(key), do: Atom.to_string(key)

  def to_key(key) when is_bitstring(key), do: key

  @doc """
  Turns a given value in to the corresponding IO List representation for YAML files. This will prepend a space before the given value and a newline after the input.
  - If given a number it will turn the number into a string and return that with a space before and a newline after the input.
  - If given a string it will return the input with a space before and a newline after the input. It will also add quotation marks around the input if that happens to contain a `:` or a ` `.
  - If given a map it will do a call to `to_yaml/2` to get the IO List representation of that.
  - If given a list it will render a YAML list.
  - If given anything else it will just return the input with a space before and a newline after it.
  """
  @spec to_value(number(), any()) :: iolist()
  def to_value(level, value) when is_map(value), do: ["\n", to_yaml(level + 1, value)]

  def to_value(level, value) when is_list(value) do
    [
      "\n",
      Enum.map(value, fn value ->
        if is_map(value) do
          [{head_k, head_v} | tail] = Map.to_list(value)

          [
            indent_level(level + 1),
            "- ",
            to_key(head_k),
            ":",
            to_value(level + 1, head_v),
            Enum.map(tail, fn {k, v} ->
              [indent_level(level + 2), to_key(k), ":", to_value(level + 2, v)]
            end)
          ]
        else
          [
            indent_level(level + 1),
            "-",
            to_value(level + 1, value)
          ]
        end
      end)
    ]
  end

  # TODO: There could be newlines or something funny in the value field
  def to_value(_level, value) when is_bitstring(value) do
    if String.contains?(value, [" ", ":"]) do
      [" ", "\"#{value}\"", "\n"]
    else
      [" ", value, "\n"]
    end
  end

  # Numbers would be interpreted as chars, need to wrap them in a string
  def to_value(_level, value) when is_number(value), do: [" ", "#{value}", "\n"]
  def to_value(_level, value), do: [" ", value, "\n"]

  defmacrop get_spacer do
    spacer =
      0..(@spacerwidth - 1)
      |> Enum.reduce("", fn _x, acc -> "#{acc}#{@spacer}" end)

    quote do
      unquote(spacer)
    end
  end

  @doc """
  Turns the given indentation level to a string that will represent that indentation.
  This can be configured by overriding `config :to_yaml, :spacer` and `config :to_yaml, :spacerwidth`

  ## Examples
    iex> ToYaml.indent_level(0)
    ""

    iex> ToYaml.indent_level(1)
    "  "

    iex> ToYaml.indent_level(2)
    "    "
  """
  @spec indent_level(number) :: String.t()
  def indent_level(level) when is_number(level) and level == 0, do: ""

  def indent_level(level) when is_number(level) do
    0..(level - 1)
    |> Enum.reduce("", fn _x, acc -> acc <> get_spacer() end)
  end
end
