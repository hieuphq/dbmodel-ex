use Mix.Config

config :dbmodel,
  module_name: "Aharooms.Schema",
  destination: "gen/",
  host: "localhost",
  port: "5432",
  dbname: "aha2",
  username: "postgres",
  password: "postgres",
  type: :postgres
