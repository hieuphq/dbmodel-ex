use Mix.Config

config :dbmodel,
  module_name: "Aharooms.Api.Schema",
  destination: "gen/schema/",
  host: "localhost",
  port: "5432",
  dbname: "aharooms_dev",
  username: "postgres",
  password: "postgres",
  type: :postgres
