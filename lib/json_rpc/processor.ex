defmodule JSONRPC.Processor do
  @callback init(keyword()) :: keyword()
  @callback call(JSONRPC.Request.t(), keyword()) :: JSONRPC.Request.t()
  @callback documented_params() :: map()
  @callback documented_result() :: map()

  defmacro __using__(_opts) do
    quote do
      @behaviour JSONRPC.Processor
      Module.register_attribute __MODULE__, :param, accumulate: true

      @spec init(keyword()) :: keyword()
      def init(opts), do: opts

      @spec call(JSONRPC.Request.t(), keyword()) :: JSONRPC.Request.t()
      def call(request, _opts), do: request

      @spec documented_result() :: map()
      def documented_result(), do: %{}

      defoverridable init: 1, call: 2, documented_result: 0

      import JSONRPC.Processor
      import JSONRPC.Request, except: [new: 1]
      @before_compile JSONRPC.Processor
    end
  end

  defmacro param(name, meta) do
    quote do
      @param {unquote(name), unquote(meta)}
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @spec documented_params() :: map()
      def documented_params() do
        @param
        |> Enum.into(%{})
        |> Jason.encode!()
        |> Jason.decode!()
      end

      defoverridable documented_params: 0
    end
  end
end
