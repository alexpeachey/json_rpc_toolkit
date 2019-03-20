defmodule JSONRPC.ActionBuilder do
  defmacro __using__(_opts) do
    quote do
      import JSONRPC.Request
      import JSONRPC.ActionBuilder
      Module.register_attribute(__MODULE__, :links, accumulate: true)
      @before_compile JSONRPC.ActionBuilder
    end
  end

  defmacro process(processor, opts \\ []) do
    quote do
      @links {unquote(processor), unquote(opts)}
    end
  end

  defmacro method(arg_name, do: block) do
    quote do
      def method(request, _opts) do
        unquote(arg_name) = request.params

        case unquote(block) do
          {:error, %JSONRPC.Error{} = error} ->
            set_error(request, error)

          {:error, error} ->
            set_error(request, JSONRPC.Error.server_error(-32_000, %{detail: error}))

          {:ok, result} ->
            set_result(request, result)

          %JSONRPC.Error{} = error ->
            set_error(request, error)

          result ->
            set_result(request, result)
        end
      end

      @links {:method, []}
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def init(), do: []
      def init(opts), do: opts

      def call(request, opts \\ [])

      def call(%JSONRPC.Request{halted: false} = request, _opts) do
        @links
        |> Enum.reverse()
        |> Enum.reduce(request, &call_processor/2)
      end

      def call(request, _opts), do: request

      defp imported_functions() do
        __ENV__.functions
        |> Enum.filter(fn {module, _functions} -> module != Kernel end)
      end

      defp call_processor({processor, opts}, %JSONRPC.Request{halted: false} = request) do
        case Atom.to_charlist(processor) do
          ~c"Elixir." ++ _ ->
            new_opts = apply(processor, :init, [opts])
            apply(processor, :call, [request, new_opts])

          _ ->
            [
              {__MODULE__, __MODULE__.__info__(:functions)}
              | Enum.filter(__ENV__.functions, fn {module, _functions} -> module != Kernel end)
            ]
            |> Enum.find(fn {module, list} -> Keyword.get(list, processor) == 2 end)
            |> case do
              {module, _} -> apply(module, processor, [request, opts])
              _ -> raise "Processor #{processor}/2 must be defined."
            end
        end
      end
    end
  end
end
