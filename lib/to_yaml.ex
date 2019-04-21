defmodule ToYaml do
  @moduledoc """
  Documentation for ToYaml.
  """

  @spacer Application.get_env(:to_yaml, :spacer)
  @spacerwidth Application.get_env(:to_yaml, :spacerwidth)

  @doc """

  ## Examples
    iex> ToYaml.to_yaml(%{"hello" => "world"})
    [["", "hello", ":", [" ", "world", "\\n"]]]

    iex> ToYaml.to_yaml(%{:hello => "world"})
    [["", "hello", ":", [" ", "world", "\\n"]]]
  """

  @spec to_yaml(map()) :: iolist()
  def to_yaml(input) when is_map(input), do: to_yaml(0, input)

  @doc """

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

  @doc """

  ## Examples
    iex> ToYaml.to_key("test")
    "test"

    iex> ToYaml.to_key(:test)
    "test"
  """
  @spec to_key(String.t() | atom()) :: String.t()
  def to_key(key) when is_atom(key), do: Atom.to_string(key)

  def to_key(key) when is_bitstring(key), do: key

  @spec to_value(number(), any()) :: iolist()
  def to_value(level, value) when is_map(value), do: ["\n", to_yaml(level + 1, value)]

  def to_value(level, value) when is_list(value) do
    [
      "\n",
      Enum.map(value, fn map ->
        [{head_k, head_v} | tail] = Map.to_list(map)

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
      end)
    ]
  end

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
