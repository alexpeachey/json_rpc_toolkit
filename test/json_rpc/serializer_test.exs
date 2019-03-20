defmodule JSONRPC.SerializerTest do
  use ExUnit.Case
  doctest JSONRPC.Serializer

  test "serializes JSON RPC responses with a result" do
    response =
      %JSONRPC.Response{
        jsonrpc: "2.0",
        result: %{sum: 5},
        error: nil,
        id: "123abc"
       }

    assert JSONRPC.Serializer.serialize(response) ==
      "{\"id\":\"123abc\",\"jsonrpc\":\"2.0\",\"result\":{\"sum\":5}}"
  end

  test "serializes JSON RPC notification results as nil" do
    assert JSONRPC.Serializer.serialize(nil) == nil
  end

  test "serializes JSON RPC responses with an error" do
    response =
      %JSONRPC.Response{
        jsonrpc: "2.0",
        result: nil,
        error: %JSONRPC.Error{code: -32_000, message: "Server error", data: %{}},
        id: "123abc"
       }

    assert JSONRPC.Serializer.serialize(response) ==
      "{\"error\":{\"code\":-32000,\"data\":{},\"message\":\"Server error\"},\"id\":\"123abc\",\"jsonrpc\":\"2.0\"}"
  end

  test "serializes JSON RPC lists of responses" do
    responses =
      [
        %JSONRPC.Response{
          jsonrpc: "2.0",
          result: %{sum: 5},
          error: nil,
          id: "123abc"
         },
         nil,
         %JSONRPC.Response{
          jsonrpc: "2.0",
          result: nil,
          error: %JSONRPC.Error{code: -32_000, message: "Server error", data: %{}},
          id: "123abd"
         }
      ]

      assert JSONRPC.Serializer.serialize(responses) ==
        "[{\"id\":\"123abc\",\"jsonrpc\":\"2.0\",\"result\":{\"sum\":5}},{\"error\":{\"code\":-32000,\"data\":{},\"message\":\"Server error\"},\"id\":\"123abd\",\"jsonrpc\":\"2.0\"}]"
  end
end
