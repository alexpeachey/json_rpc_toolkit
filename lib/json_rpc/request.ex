defmodule JSONRPC.Request do
  alias __MODULE__
  alias JSONRPC.{Error, Response}

  defstruct [
    :method,
    :params,
    :type,
    halted: false,
    jsonrpc: "2.0",
    result: nil,
    error: nil,
    id: nil,
    assigns: %{}
  ]

  @type t :: %Request{}

  @spec new(map()) :: Request.t()
  def new(%{"jsonrpc" => "2.0", "method" => method, "params" => params, "id" => id}) do
    %Request{method: method, params: params, id: id, type: :method}
  end

  def new(%{method: method, params: params, id: id, type: :method}) do
    %Request{method: method, params: params, id: id, type: :method}
  end

  def new(%{"jsonrpc" => "2.0", "method" => method, "id" => id}) do
    %Request{method: method, id: id, type: :method}
  end

  def new(%{method: method, id: id, type: :method}) do
    %Request{method: method, id: id, type: :method}
  end

  def new(%{"jsonrpc" => "2.0", "method" => method, "params" => params}) do
    %Request{method: method, params: params, type: :notification}
  end

  def new(%{method: method, params: params, type: :notification}) do
    %Request{method: method, params: params, type: :notification}
  end

  def new(%{"jsonrpc" => "2.0", "method" => method}) do
    %Request{method: method, type: :notification}
  end

  def new(%{method: method, type: :notification}) do
    %Request{method: method, type: :notification}
  end

  def new(%{} = blob) do
    %Request{id: blob["id"]}
    |> set_error(Error.invalid_request())
    |> halt()
  end

  def new(_blob) do
    %Request{}
    |> set_error(Error.invalid_request())
    |> halt()
  end

  @spec assign(Request.t(), atom(), any()) :: Request.t()
  def assign(request, key, value) when is_atom(key) do
    %{request | assigns: Map.put(request.assigns, key, value)}
  end

  @spec halt(Request.t()) :: Request.t()
  def halt(request) do
    %{request | halted: true}
  end

  @spec set_error(Request.t(), Error.t()) :: Request.t()
  def set_error(request, error) do
    %{request | error: error}
  end

  @spec set_params(Request.t(), map() | list()) :: Request.t()
  def set_params(request, params) do
    %{request | params: params}
  end

  @spec set_result(Request.t(), any()) :: Request.t()
  def set_result(request, result) do
    %{request | result: result}
  end

  @spec to_response(Request.t()) :: Response.t()
  def to_response(%Request{jsonrpc: version, id: id, result: nil, error: nil}) do
    %Response{
      jsonrpc: version,
      id: id,
      error: Error.internal_error(%{detail: "Neither result or error were set"})
    }
  end

  def to_response(%Request{jsonrpc: version, id: id, result: result, error: nil}) do
    %Response{jsonrpc: version, id: id, result: result}
  end

  def to_response(%Request{jsonrpc: version, id: id, result: nil, error: error}) do
    %Response{jsonrpc: version, id: id, error: error}
  end

  def to_response(%Request{jsonrpc: _version}), do: nil
end
