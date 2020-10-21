defmodule Dbmodel.Database.Table do
  defstruct columns: [Dbmodel.Database.Column], name: ""

  def table_name(table_name) do
    table_name
    |> String.split("_")
    |> Enum.map(fn x -> String.capitalize(x) end)
    |> Enum.reduce(fn x, acc -> acc <> x end)
  end
end
