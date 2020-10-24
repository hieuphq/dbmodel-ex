defmodule Mix.Tasks.Gen.Django do
  use Mix.Task

  @shortdoc "Generate django model from database"
  def run(_) do
    {:ok, _started} = Application.ensure_all_started(:postgrex)
    configs = Dbmodel.Config.load_configs()

    {header, output} =
      configs
      |> Dbmodel.Database.Factory.init()
      |> Dbmodel.Database.connect()
      |> Dbmodel.Database.get_tables()
      |> Enum.map(fn x -> {x, Dbmodel.Database.get_columns(x.database, x)} end)
      |> Enum.map(fn {header, columns} ->
        %Dbmodel.Database.Table{name: header.name, columns: columns}
      end)
      |> Enum.map(fn table -> Dbmodel.IO.Django.prepare(table, configs.project.name) end)
      |> Enum.map(fn {_header, output} -> output end)
      |> Enum.join("\n")
      |> build_file()

    Dbmodel.IO.Django.write(output, header, configs.project.output_dir <> "django/")
  end

  defp build_file(content) do
    output =
      "from django.db import models" <>
        "\n\n" <>
        content

    {"models", output}
  end
end
