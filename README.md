# Dbmodel

Generate schema model from database

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `dbmodel` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dbmodel, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/dbmodel](https://hexdocs.pm/dbmodel).

## Configuration

Append the below config into `config/`. It can placed `config.exs` or `develop.exs`
```elixir
config :dbmodel,
  module_name: "Aharooms.Api.Schema",
  destination: "gen/",
  host: "localhost",
  port: "5432",
  dbname: "aharooms_dev",
  username: "postgres",
  password: "postgres",
  type: :postgres

```

- module_name: name for generating the package's file
- destination: location to storing the schema files
- host: db host
- port: db port
- dbname: database name
- username: db username
- password: db password
- type:
  - :postgres
  - :mysql


## Generate schema
```elixir
mix gen.schema
```

## Generate django
```elixir
mix gen.django
```
