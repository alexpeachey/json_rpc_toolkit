# JSON-RPC Toolkit

The JSON-RPC Toolkit provides a transport agnostic implementation of the JSON-RPC 2.0 protocol.
It also provides optional support for Phoenix HTTP and Web Sockets as those are the most likely transports people will use.


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `json_rpc_toolkit` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:json_rpc_toolkit, "~> 0.9.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/json_rpc_toolkit](https://hexdocs.pm/json_rpc_toolkit).

## Warning

This library is pre-1.0. One of the primary things missing is a full set of tests to verify it's working condition.
It has had some testing by bathing in fire as it is added into a private project, but the actual set of tests in
this repo is lacking and it is not recommended the library is used until the tests are in decent shape and the library
is bumped to 1.0.0. The other thing missing is documentation and there are unfortunately, no hex docs yet.
