defmodule JSONRPC.Registry do
  defmacro __using__(opts) do
    namespace_separator = Keyword.get(opts, :separator, ".")

    quote do
      use JSONRPC.Processor
      import JSONRPC.Registry
      @scope [%{name: "", pre: [], scoped: [], post: []}]
      @registry %{}
      @namespace_separator unquote(namespace_separator)
      @before_compile JSONRPC.Registry
    end
  end

  defmacro namespace(name, do: block) do
    quote do
      @scope [%{name: unquote(name), pre: [], scoped: [], post: []} | @scope]

      unquote(block)

      @scope [
        %{
          hd(tl(@scope))
          | scoped:
              Enum.map(hd(@scope).scoped, fn {method, chain} ->
                {unquote(name) <> @namespace_separator <> method,
                 hd(@scope).pre ++ chain ++ hd(@scope).post}
              end) ++ hd(tl(@scope)).scoped
        }
        | tl(tl(@scope))
      ]
    end
  end

  defmacro process(processor, opts \\ []) do
    quote do
      case hd(@scope) do
        %{scoped: []} ->
          @scope [
            %{
              hd(@scope)
              | pre: hd(@scope).pre ++ [{unquote(processor), unquote(opts)}]
            }
            | tl(@scope)
          ]

        _ ->
          @scope [
            %{
              hd(@scope)
              | post: hd(@scope).post ++ [{unquote(processor), unquote(opts)}]
            }
            | tl(@scope)
          ]
      end
    end
  end

  defmacro register(action, module) do
    quote do
      @scope [
        %{
          hd(@scope)
          | scoped: hd(@scope).scoped ++ [{unquote(action), [{unquote(module), []}]}]
        }
        | tl(@scope)
      ]
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @registry hd(@scope).scoped
                |> Enum.map(fn {method, chain} ->
                  {method, hd(@scope).pre ++ chain ++ hd(@scope).post}
                end)
                |> Enum.into(%{})

      def registry(), do: @registry

      def init(opts), do: opts

      def call(%JSONRPC.Request{method: method, halted: false} = request, opts) do
        @registry
        |> Map.get(method)
        |> execute_chain(request, opts)
      end

      def call(request, _opts), do: request

      def execute_chain(_, %JSONRPC.Request{halted: true} = request, _opts), do: request

      def execute_chain(nil, request, _opts) do
        request
        |> JSONRPC.Request.set_error(JSONRPC.Error.method_not_found())
        |> JSONRPC.Request.halt()
      end

      def execute_chain([], request, _opts), do: request

      def execute_chain([{processor, opts} | tail], request, registry_opts) do
        tail
        |> execute_chain(
          call_processor({processor, opts ++ registry_opts}, request),
          registry_opts
        )
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

      defp call_processor(_, request), do: request
    end
  end
end
