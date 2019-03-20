defmodule JSONRPC.Serializer do
  alias JSONRPC.{Response, Error}

  @spec serialize(Response.t() | list(Response.t())) :: String.t() | nil
  def serialize(results) when is_list(results) do
    results
    |> Enum.map(&extract/1)
    |> Enum.reject(&is_nil/1)
    |> Jason.encode!()
  end

  def serialize(nil), do: nil

  def serialize(result) do
    result
    |> extract()
    |> Jason.encode!()
  end

  defp extract(nil), do: nil

  defp extract(%Response{jsonrpc: jsonrpc, id: id, result: result, error: nil}) do
    %{
      jsonrpc: jsonrpc,
      id: id,
      result: result
    }
  end

  defp extract(%Response{jsonrpc: jsonrpc, id: id, error: error, result: nil}) do
    %{
      jsonrpc: jsonrpc,
      id: id,
      error: extract(error)
    }
  end

  defp extract(%Error{code: code, message: message, data: data}) do
    %{
      code: code,
      message: message,
      data: data
    }
  end
end
