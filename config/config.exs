use Mix.Config

config :dbmodel,
  module_name: "Aharooms.Schema",
  destination: "gen/",
  host: "51.79.173.200",
  port: "5432",
  dbname: "aharooms_dev",
  username: "postgres",
  password: "nhaemcomotconbo",
  type: :postgres
