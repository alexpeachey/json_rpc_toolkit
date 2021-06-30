defmodule JSONRPC.Method do
  defmacro __using__(_opts) do
    quote do
      Module.register_attribute __MODULE__, :methoddoc, accumulate: true
      import JSONRPC.Method
      @before_compile JSONRPC.Method
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

    description = quote do
      __MODULE__
      |> to_string()
      |> String.split(".")
      |> Enum.reverse()
      |> tl()
      |> Enum.reverse()
      |> Enum.join(".")
      |> String.to_atom()
      |> apply(:method_descriptions, [])
      |> Map.get(
        unquote(module_name)
        |> to_string()
        |> String.split(".")
        |> Enum.reverse()
        |> hd()
        |> String.to_atom()
      )
    end

    quote do
      defmodule unquote(module_name) do
        use JSONRPC.ActionBuilder

        unquote(pre)
        method(unquote(arg_name), do: unquote(block))
        unquote(post)

        def description() do
          unquote(description)
        end
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def method_descriptions() do
        @methoddoc
        |> List.flatten
        |> Enum.into(%{})
      end
    end
  end
end
