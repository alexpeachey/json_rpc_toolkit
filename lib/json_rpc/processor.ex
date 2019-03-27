defmodule JSONRPC.Processor do
  @callback init(keyword()) :: keyword()
  @callback call(JSONRPC.Request.t(), keyword()) :: JSONRPC.Request.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour JSONRPC.Processor

      @spec init(keyword()) :: keyword()
      def init(opts), do: opts

      @spec call(JSONRPC.Request.t(), keyword()) :: JSONRPC.Request.t()
      def call(request, _opts), do: request

      defoverridable init: 1, call: 2

      import JSONRPC.Request, except: [new: 1]
    end
  end
end
