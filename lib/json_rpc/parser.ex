defmodule JSONRPC.Parser do
  alias JSONRPC.{Request, Response, Error}

  @spec parse(map() | String.t()) ::
          Request.t() | Response.t() | Error.t() | list(Request.t() | Response.t() | Error.t())
  def parse(%{"jsonrpc" => "2.0", "method" => _method} = request) do
    Request.new(request)
  end

  def parse(%{"jsonrpc" => "2.0", "result" => _result} = response) do
    Response.new(response)
  end

  def parse(%{"jsonrpc" => "2.0", "error" => _error} = response) do
    Response.new(response)
  end

  def parse(requests) when is_list(requests) do
    requests
    |> Enum.map(&parse/1)
  end

  def parse(blob) when is_binary(blob) do
    case Jason.decode(blob) do
      {:ok, decoded} -> parse(decoded)
      {:error, _} -> Error.parse_error()
    end
  end

  def parse(_) do
    Error.invalid_request()
  end
end
