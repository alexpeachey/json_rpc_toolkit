defmodule JSONRPC.Error do
  alias __MODULE__

  defstruct [:code, :message, data: %{}]

  @type t :: %Error{}

  @parse_error -32700
  @invalid_request -32600
  @method_not_found -32601
  @invalid_params -32602
  @internal_error -32603
  @server_error -32000

  @spec new(map()) :: Error.t()
  def new(%{"code" => code, "message" => message, "data" => data}) do
    %Error{code: code, message: message, data: data}
  end

  def new(%{code: code, message: message, data: data}) do
    %Error{code: code, message: message, data: data}
  end

  def new(%{"code" => code, "message" => message}) do
    %Error{code: code, message: message}
  end

  def new(%{code: code, message: message}) do
    %Error{code: code, message: message}
  end

  def new(_) do
    internal_error()
  end

  @spec parse_error() :: Error.t()
  def parse_error() do
    %Error{code: @parse_error, message: "Parse error"}
  end

  @spec invalid_request() :: Error.t()
  def invalid_request() do
    %Error{code: @invalid_request, message: "Invalid Request"}
  end

  @spec method_not_found() :: Error.t()
  def method_not_found(data \\ %{}) do
    %Error{code: @method_not_found, message: "Method not found", data: data}
  end

  @spec invalid_params() :: Error.t()
  def invalid_params(data \\ %{}) do
    %Error{code: @invalid_params, message: "Invalid params", data: data}
  end

  @spec internal_error() :: Error.t()
  def internal_error(data \\ %{}) do
    %Error{code: @internal_error, message: "Internal error", data: data}
  end

  @spec server_error() :: Error.t()
  def server_error(code \\ @server_error, data \\ %{}) do
    %Error{code: code, message: "Server error", data: data}
  end

  @spec application_error(integer(), String.t(), any()) :: Error.t()
  def application_error(code, message, data \\ %{}) do
    %Error{code: code, message: message, data: data}
  end
end
