defmodule Mix.Tasks.Gen.Schema do
  use Mix.Task

  @shortdoc "Generate ecto schema from database"
  def run(_) do
    {:ok, _started} = Application.ensure_all_started(:postgrex)
    configs = Dbmodel.Config.load_configs()

    configs
    |> Dbmodel.Database.Factory.init()
    |> Dbmodel.Database.connect()
    |> Dbmodel.Database.get_tables()
    |> Enum.map(fn x -> {x, Dbmodel.Database.get_columns(x.database, x)} end)
    |> Enum.map(fn {header, columns} ->
      %Dbmodel.Database.Table{name: header.name, columns: columns}
    end)
    |> Enum.map(fn table ->
      Dbmodel.IO.Export.prepare(table, configs.project.name)
    end)
    |> Enum.map(fn {header, output} ->
      Dbmodel.IO.Export.write(output, header, configs.project.output_dir <> "/schema/")
    end)
  end
end
