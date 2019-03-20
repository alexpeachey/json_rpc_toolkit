defmodule JSONRPC.ParserTest do
  use ExUnit.Case
  doctest JSONRPC.Parser

  test "parses JSON RPC requests" do
    request =
      "{\"jsonrpc\":\"2.0\",\"id\":\"123abc\",\"method\":\"test.add\",\"params\":{\"x\":2,\"y\":3}}"

    assert JSONRPC.Parser.parse(request) == %JSONRPC.Request{
             error: nil,
             halted: false,
             id: "123abc",
             jsonrpc: "2.0",
             method: "test.add",
             params: %{"x" => 2, "y" => 3},
             result: nil,
             type: :method
           }

    request = "{\"jsonrpc\":\"2.0\",\"method\":\"test.report\",\"params\":{\"message\":\"ok\"}}"

    assert JSONRPC.Parser.parse(request) == %JSONRPC.Request{
             error: nil,
             halted: false,
             id: nil,
             jsonrpc: "2.0",
             method: "test.report",
             params: %{"message" => "ok"},
             result: nil,
             type: :notification
           }
  end

  test "parses JSON RPC responses" do
    response = "{\"jsonrpc\":\"2.0\",\"id\":\"123abc\",\"result\":{\"sum\":5}}"

    assert JSONRPC.Parser.parse(response) == %JSONRPC.Response{
             error: nil,
             id: "123abc",
             jsonrpc: "2.0",
             result: %{"sum" => 5}
           }
  end

  test "parses JSON RPC errors" do
    error =
      "{\"jsonrpc\":\"2.0\",\"id\":\"123abc\",\"error\":{\"code\":-32000,\"message\":\"Server error\",\"data\":{}}}"

    assert JSONRPC.Parser.parse(error) == %JSONRPC.Response{
             id: "123abc",
             jsonrpc: "2.0",
             error: %JSONRPC.Error{code: -32_000, message: "Server error", data: %{}},
             result: nil
           }
  end

  test "parses JSON RPC bulk requests" do
    requests =
      [
        "{\"jsonrpc\":\"2.0\",\"id\":\"123abc\",\"method\":\"test.add\",\"params\":{\"x\":2,\"y\":3}}",
        "{\"jsonrpc\":\"2.0\",\"method\":\"test.report\",\"params\":{\"message\":\"ok\"}}"
      ]

    assert JSONRPC.Parser.parse(requests) ==
      [
        %JSONRPC.Request{
          error: nil,
          halted: false,
          id: "123abc",
          jsonrpc: "2.0",
          method: "test.add",
          params: %{"x" => 2, "y" => 3},
          result: nil,
          type: :method
        },
        %JSONRPC.Request{
          error: nil,
          halted: false,
          id: nil,
          jsonrpc: "2.0",
          method: "test.report",
          params: %{"message" => "ok"},
          result: nil,
          type: :notification
        }
      ]
  end
end
