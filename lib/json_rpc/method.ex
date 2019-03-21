defmodule JSONRPC.Method do
  defmacro __using__(_opts) do
    quote do
      import JSONRPC.Method
    end
  end

  defmacro defmethod(module_name, arg_name, opts, do: block) do
    pre =
      opts
      |> Keyword.get(:pre, [])
      |> List.wrap()
      |> Enum.map(fn
        {processor, popts} -> quote do: process(unquote(processor), unquote(popts))
        processor -> quote do: process(unquote(processor))
      end)

    post =
      opts
      |> Keyword.get(:post, [])
      |> List.wrap()
      |> Enum.map(fn
        {processor, popts} -> quote do: process(unquote(processor), unquote(popts))
        processor -> quote do: process(unquote(processor))
      end)

    quote do
      defmodule unquote(module_name) do
        use JSONRPC.ActionBuilder

        unquote(pre)
        method(unquote(arg_name), do: unquote(block))
        unquote(post)
      end
    end
  end
end
