defmodule ToYamlTest do
  use ExUnit.Case
  doctest ToYaml

  @testfiledir Application.app_dir(:to_yaml, "priv/test")

  defp list_to_string(list) do
    "#{list}"
  end

  # test "greets the world" do
  #  assert ToYaml.hello() == :world
  # end

  test "to_yaml transforms a simple list" do
    input = %{
      "hello" => "world",
      :foo => "bar"
    }

    expected = File.read!("#{@testfiledir}/simple.yaml")
    result = input |> ToYaml.to_yaml() |> list_to_string()
    assert result == expected
  end

  test "to_yaml transforms a nested list" do
    input = %{
      :hello => %{
        :world => "earth",
        "yeah" => "boi"
      }
    }

    expected = File.read!("#{@testfiledir}/nested.yaml")
    result = input |> ToYaml.to_yaml() |> list_to_string()
    assert result == expected
  end

  test "to_yaml transforms an array thingy" do
    input = %{
      :list => [
        %{
          :key => "value",
          :sub => "yeah"
        },
        %{
          :keytwo => "valuetwo",
          :sub => "wooo"
        }
      ]
    }

    expected = File.read!("#{@testfiledir}/list.yaml")
    result = input |> ToYaml.to_yaml() |> list_to_string()
    assert result == expected
  end

  test "converts to a correct kubernetes service definition" do
    input = %{
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

    expected = File.read!("#{@testfiledir}/kube_service.yaml")
    result = input |> ToYaml.to_yaml() |> list_to_string()
    assert result == expected
  end
end
