defmodule JSONRPC.Processor do
  @callback init(keyword()) :: keyword()
  @callback call(JSONRPC.Request.t(), keyword()) :: JSONRPC.Request.t()
  @callback documented_params() :: [JSONRPC.Attribute.t()]
  @callback documented_result() :: [JSONRPC.Attribute.t()]

  defmacro __using__(_opts) do
    quote do
      @behaviour JSONRPC.Processor

      @spec init(keyword()) :: keyword()
      def init(opts), do: opts

      @spec call(JSONRPC.Request.t(), keyword()) :: JSONRPC.Request.t()
      def call(request, _opts), do: request

      @spec documented_params() :: [JSONRPC.Attribute.t()]
      def documented_params(), do: []

      @spec documented_result() :: [JSONRPC.Attribute.t()]
      def documented_result(), do: []

      defoverridable init: 1, call: 2, documented_params: 0, documented_result: 0

      import JSONRPC.Request, except: [new: 1]
    end
  end
end
