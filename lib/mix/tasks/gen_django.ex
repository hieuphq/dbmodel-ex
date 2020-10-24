defmodule Mix.Tasks.Gen.Django do
  use Mix.Task

  @shortdoc "Generate django model from database"
  def run(_) do
    {:ok, _started} = Application.ensure_all_started(:postgrex)
    configs = Dbmodel.Config.load_configs()

    configs
    |> Dbmodel.Database.Factory.init()
    |> Dbmodel.Database.connect()
    |> Dbmodel.Database.get_tables()
    |> Enum.map(fn x -> {x, Dbmodel.Database.get_columns(x.database, x)} end)
    |> build_model(configs.project.name)
    |> Enum.map(fn {header, output} ->
      Dbmodel.IO.Django.write(output, header, configs.project.output_dir <> "django/")
    end)
  end

  defp build_model(db, project_name) do
    model =
      db
      |> Enum.map(fn {header, columns} ->
        %Dbmodel.Database.Table{name: header.name, columns: columns}
      end)
      |> Enum.map(fn table -> Dbmodel.IO.Django.prepare(table, project_name) end)
      |> Enum.map(fn {_header, output} -> output end)
      |> Enum.join("\n")
      |> build_model_file()

    table_names =
      db
      |> Enum.map(fn {header, _columns} ->
        Dbmodel.Database.Table.table_name(header.name)
      end)

    admin =
      db
      |> Enum.map(fn {header, columns} ->
        %Dbmodel.Database.Table{name: header.name, columns: columns}
      end)
      |> Enum.map(fn table -> Dbmodel.IO.Django.prepare_admin(table, project_name) end)
      |> Enum.map(fn {_header, output} -> output end)
      |> Enum.join("\n")
      |> build_admin_file(table_names)

    [model, admin]
  end

  defp build_model_file(content) do
    output =
      "from django.db import models" <>
        "\n\n" <>
        content

    {"models", output}
  end

  defp build_admin_file(content, table_names) do
    output =
      "from django.contrib import admin" <>
        "\n\n" <>
        "# Register your models here.\n" <>
        "from .models import #{Enum.join(table_names, ", ")}" <>
        "\n\n" <>
        content

    {"admin", output}
  end
end
