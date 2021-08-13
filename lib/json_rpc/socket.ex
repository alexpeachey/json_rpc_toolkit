if Code.ensure_loaded?(Phoenix.Transports.WebSocket) do
  defmodule JSONRPC.Socket do
    defmacro __using__(opts) do
      registry = Keyword.get(opts, :registry)
      timeout = Keyword.get(opts, :timeout, 5000)

      quote do
        use Phoenix.Socket
        transport(:websocket, Phoenix.Transports.WebSocket)
        transport(:longpoll, Phoenix.Transports.LongPoll)
        channel("jsonrpc", JSONRPC.Channel)

        @registry unquote(registry)

        def connect(params, socket) do
          socket =
            socket
            |> Phoenix.Socket.assign(:connection_params, params)
            |> Phoenix.Socket.assign(:registry, @registry)
            |> Phoenix.Socket.assign(:timeout, unquote(timeout))

          {:ok, socket}
        end

        def id(_socket), do: nil
      end
    end
  end
end
