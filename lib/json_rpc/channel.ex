if Code.ensure_loaded?(Phoenix.Channel) do
  defmodule JSONRPC.Channel do
    use Phoenix.Channel
    alias Phoenix.Socket
    alias JSONRPC.{Parser, Request}

    def join("jsonrpc", _message, socket) do
      {:ok, socket}
    end

    def handle_in("jsonrpc", message, socket) do
      message
      |> Parser.parse()
      |> handle_message(socket.assigns.connection_params, socket.assigns.registry)
      |> case do
        [_, _] = responses -> {:reply, {:ok, Enum.reject(responses, &is_nil/1)}, socket}
        %{error: nil} = response -> {:reply, {:ok, response}, socket}
        %{result: nil} = response -> {:reply, {:error, response}, socket}
      end
    end

    defp handle_message(requests, params, registry) when is_list(requests) do
      Enum.map(requests, &handle_message(&1, params, registry))
    end

    defp handle_message(request, params, registry) do
      registry
      |> apply(:call, [request, [connection_params: params]])
      |> Request.to_response()
    end
  end
end
