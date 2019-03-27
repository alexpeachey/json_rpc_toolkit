if Code.ensure_loaded?(Plug.Conn) do
  defmodule JSONRPC.Plug do
    import Plug.Conn
    alias JSONRPC.{Request, Response, Error, Parser, Serializer}

    @type options :: [mount: String.t(), registry: module()]

    @spec init(keyword()) :: options()
    def init(options) do
      mount =
        options
        |> Keyword.get(:mount, "/rpc")
        |> String.split("/", trim: true)

      registry = Keyword.get(options, :registry)

      on_error = Keyword.get(options, :on_error)

      [mount: mount, registry: registry, on_error: on_error]
    end

    @spec call(Plug.Conn.t(), options()) :: Plug.Conn.t()
    def call(%{method: "POST", path_info: mount} = conn,
          mount: mount,
          registry: registry,
          on_error: on_error
        ) do
      {body, conn} = get_body(conn)

      body
      |> Parser.parse()
      |> case do
        requests when is_list(requests) ->
          Enum.map(requests, fn request ->
            Request.to_response(apply(registry, :call, [request, [conn: conn]]))
          end)
          |> Serializer.serialize()
          |> send_response(conn, on_error)

        %Request{} = request ->
          registry
          |> apply(:call, [request, [conn: conn]])
          |> Request.to_response()
          |> send_response(conn, on_error)

        %Error{} = error ->
          error = call_error_handler(on_error, error)

          %Response{error: error}
          |> Serializer.serialize()
          |> send_error(conn)
      end
    end

    def call(conn, _opts), do: conn

    defp send_response(response, conn, _) when is_binary(response) do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, response)
      |> halt()
    end

    defp send_response(%{error: nil} = response, conn, _) do
      response = Serializer.serialize(response)

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, response)
      |> halt()
    end

    defp send_response(%{error: error} = response, conn, on_error) do
      response =
        response
        |> Map.put(:error, call_error_handler(on_error, error))
        |> Serializer.serialize()

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(400, response)
      |> halt()
    end

    defp send_error(error, conn) do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(400, error)
      |> halt()
    end

    defp get_body(conn, partial \\ []) do
      case read_body(conn) do
        {:ok, body, conn} ->
          {IO.iodata_to_binary([partial | body]), conn}

        {:more, body, conn} ->
          get_body(conn, [partial | body])

        {:error, _error} ->
          {"", conn}
      end
    end

    defp call_error_handler(nil, error), do: error

    defp call_error_handler(on_error, error) do
      on_error.(error)
    end
  end
end
