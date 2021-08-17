defmodule JSONRPC.Response do
  alias __MODULE__
  alias JSONRPC.Error

  defstruct jsonrpc: "2.0",
            result: nil,
            error: nil,
            id: nil

  @type t :: %Response{}

  @spec new(map()) :: Response.t()
  def new(%{"jsonrpc" => "2.0", "result" => result, "id" => id}) do
    %Response{result: result, id: id}
  end

  def new(%{"jsonrpc" => "2.0", "error" => error, "id" => id}) do
    %Response{error: Error.new(error), id: id}
  end

  def new(%{"jsonrpc" => "2.0", "error" => error}) do
    %Response{error: Error.new(error)}
  end

  def new(_) do
    %Response{error: Error.internal_error()}
  end

  def finalize_async_response({{:ok, value}, _}), do: value
  def finalize_async_response({_, request}) do
    %Response{
      id: request.id,
      error: JSONRPC.Error.internal_error()
    }
  end
end
