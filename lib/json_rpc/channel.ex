if Code.ensure_loaded?(Phoenix.Channel) do
  defmodule JSONRPC.Channel do
    use Phoenix.Channel
    alias JSONRPC.{Parser, Request, Response}

    def join("jsonrpc", _message, socket) do
      {:ok, socket}
    end

    def handle_in("jsonrpc", message, socket) do
      message
      |> Parser.parse()
      |> handle_message(socket.assigns.connection_params, socket.assigns.registry, socket.assigns.timeout)
      |> case do
        [_, _] = responses -> {:reply, {:ok, Enum.reject(responses, &is_nil/1)}, socket}
        %{error: nil} = response -> {:reply, {:ok, response}, socket}
        %{result: nil} = response -> {:reply, {:error, response}, socket}
      end
    end

    def handle_message(requests, params, registry, timeout) when is_list(requests) do
      Task.Supervisor.async_stream_nolink(
        JSONRPC.TaskSupervisor,
        requests,
        __MODULE__,
        :handle_message,
        [params, registry],
        [ordered: true, timeout: timeout, on_timeout: :kill_task]
      )
      |> Enum.zip(requests)
      |> Enum.map(&Response.finalize_async_response/1)
    end

    def handle_message(request, params, registry, _timeout) do
      registry
      |> apply(:call, [request, [connection_params: params]])
      |> Request.to_response()
    end
  end
end
