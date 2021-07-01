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

    summary =
      opts
      |> Keyword.get(:summary, "")

    description =
      opts
      |> Keyword.get(:description, "")

    method_params =
      quote do
        unquote(opts)
        |> Keyword.get(:documented_params, %{})
        |> List.wrap()
      end

    pre_processor_params =
      quote do
        unquote(opts)
        |> Keyword.get(:pre, [])
        |> List.wrap()
        |> Enum.map(fn
          {processor, _} -> apply(processor, :documented_params, [])
          processor -> apply(processor, :documented_params, [])
        end)
      end

    post_processor_params =
      quote do
        unquote(opts)
        |> Keyword.get(:post, [])
        |> List.wrap()
        |> Enum.map(fn
          {processor, _} -> apply(processor, :documented_params, [])
          processor -> apply(processor, :documented_params, [])
        end)
      end

    documented_params =
      quote do
        (unquote(pre_processor_params) ++ unquote(method_params) ++ unquote(post_processor_params))
        |> Enum.reduce(%{}, fn (p, r) -> Map.merge(r,p) end)
      end

    method_result =
      quote do
        unquote(opts)
        |> Keyword.get(:documented_result, %{})
        |> List.wrap()
      end

    pre_processor_result =
      quote do
        unquote(opts)
        |> Keyword.get(:pre, [])
        |> List.wrap()
        |> Enum.map(fn
          {processor, _} -> apply(processor, :documented_result, [])
          processor -> apply(processor, :documented_result, [])
        end)
      end

    post_processor_result =
      quote do
        unquote(opts)
        |> Keyword.get(:post, [])
        |> List.wrap()
        |> Enum.map(fn
          {processor, _} -> apply(processor, :documented_result, [])
          processor -> apply(processor, :documented_result, [])
        end)
      end

    documented_result =
      quote do
        (unquote(pre_processor_result) ++ unquote(method_result) ++ unquote(post_processor_result))
        |> Enum.reject(fn result -> result == %{} end)
        |> List.last()
      end

    quote do
      defmodule unquote(module_name) do
        use JSONRPC.ActionBuilder

        unquote(pre)
        method(unquote(arg_name), do: unquote(block))
        unquote(post)

        def summary() do
          unquote(summary)
        end

        def description() do
          unquote(description)
        end

        def documented_params() do
          unquote(documented_params)
        end

        def documented_result() do
          unquote(documented_result)
        end
      end
    end
  end
end
