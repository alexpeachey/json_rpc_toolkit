if Code.ensure_loaded?(Plug.Conn) do
  defmodule JSONRPC.Plug do
    import Plug.Conn
    alias JSONRPC.{Request, Response, Error, Parser, Serializer}

    @type options :: [mount: String.t(), registry: module(), timeout: integer(), on_error: function()]

    @spec init(keyword()) :: options()
    def init(options) do
      mount =
        options
        |> Keyword.get(:mount, "/rpc")
        |> String.split("/", trim: true)

      registry = Keyword.get(options, :registry)

      timeout = Keyword.get(options, :timeout, 5000)

      on_error = Keyword.get(options, :on_error)

      [mount: mount, registry: registry, timeout: timeout, on_error: on_error]
    end

    @spec call(Plug.Conn.t(), options()) :: Plug.Conn.t()
    def call(%{method: "POST", path_info: mount} = conn,
          mount: mount,
          registry: registry,
          timeout: timeout,
          on_error: on_error
        ) do
      {body, conn} = get_body(conn)

      body
      |> Parser.parse()
      |> case do
        requests when is_list(requests) ->
          Task.Supervisor.async_stream_nolink(
            JSONRPC.TaskSupervisor,
            requests,
            __MODULE__,
            :process_request,
            [registry, conn],
            [ordered: true, timeout: timeout, on_timeout: :kill_task]
          )
          |> Enum.zip(requests)
          |> Enum.map(&Response.finalize_async_response/1)
          |> Serializer.serialize()
          |> send_response(conn, on_error)

        %Request{} = request ->
          request
          |> process_request(registry, conn)
          |> send_response(conn, on_error)

        %Error{} = error ->
          error = call_error_handler(on_error, error)

          %Response{error: error}
          |> Serializer.serialize()
          |> send_error(conn)
      end
    end

    def call(conn, _opts), do: conn

    def process_request(request, registry, conn) do
      registry
      |> apply(:call, [request, [conn: conn]])
      |> Request.to_response()
    end

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
