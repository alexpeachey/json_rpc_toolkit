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

      [mount: mount, registry: registry]
    end

    @spec call(Plug.Conn.t(), options()) :: Plug.Conn.t()
    def call(%{method: "POST", path_info: mount} = conn, mount: mount, registry: registry) do
      {body, conn} = get_body(conn)

      body
      |> Parser.parse()
      |> case do
        requests when is_list(requests) ->
          Enum.map(requests, fn request ->
            Request.to_response(apply(registry, :call, [request, [conn: conn]]))
          end)
          |> Serializer.serialize()
          |> send_response(conn)

        %Request{} = request ->
          registry
          |> apply(:call, [request, [conn: conn]])
          |> Request.to_response()
          |> send_response(conn)

        %Error{} = error ->
          %Response{error: error}
          |> Serializer.serialize()
          |> send_error(conn)
      end
    end

    def call(conn, _opts), do: conn

    defp send_response(%{error: nil} = response, conn) do
      response = Serializer.serialize(response)

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, response)
      |> halt()
    end

    defp send_response(error, conn) do
      error = Serializer.serialize(error)

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(400, error)
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
  end
end
