defmodule Dbmodel.Database.Factory do
  @spec init(Dbmodel.Config.t()) :: Dbmodel.Database.t()
  def init(configs) do
    case configs.db.type do
      :postgres ->
        IO.puts("Using PostgreSQL...")
        Dbmodel.Database.create(%Dbmodel.Database.Pg{}, configs)

      _ ->
        IO.puts("Using default database MySql...")
        Dbmodel.Database.create(%Dbmodel.Database.Pg{}, configs)
    end
  end
end
