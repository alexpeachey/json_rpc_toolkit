defmodule JSONRPC.Attribute do
  defstruct [
    :name,
    :type,
    :description,
    :inner_attributes
  ]

  @type t :: %JSONRPC.Attribute{}
end
