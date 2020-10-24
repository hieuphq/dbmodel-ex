defmodule Dbmodel.IO.Django do
  @doc """
    Generate the django model based on the database type
  """
  # @ignore_fields ["created_at", "updated_at", "deleted_at", "inserted_at"]
  @created_time_fields ["created_at", "inserted_at"]
  @updated_time_fields ["updated_at"]

  @doc """
    Write the given schema to file.
  """
  @spec write(String.t(), String.t(), String.t()) :: Any
  def write(schema, name, path \\ "") do
    case File.open("#{path}#{name}.py", [:write]) do
      {:ok, file} ->
        IO.puts("#{path}#{name}.py")
        IO.binwrite(file, schema)
        File.close(file)

      {_, msg} ->
        IO.puts("Could not write #{name} to file: #{msg}")
    end
  end

  @spec prepare(Dbmodel.Database.Table.t(), String.t()) :: {String.t(), String.t()}
  def prepare(table, _project_name) do
    columns = table.columns

    output = module_declaration(table.name)

    trimmed_columns = remove_foreign_keys(columns)

    column_output =
      trimmed_columns
      |> Enum.reduce("", fn column, a ->
        a <> type_output({column.name, column.type, column.primary_key})
      end)

    output =
      output <>
        column_output <>
        "\n" <>
        table_declaration(table.name) <>
        "\n" <>
        title_declaration(columns)

    {table.name, output}
  end

  # def import_declaration do
  #   "from django.db import models" <> "\n"
  # end

  def module_declaration(table_name) do
    class_name = Dbmodel.Database.Table.table_name(table_name)
    "class #{class_name}(models.Model):" <> "\n"
  end

  def one_tab(text) do
    "    " <> text
  end

  def two_tab(text) do
    "    " <> "    " <> text
  end

  def table_declaration(table_name) do
    output = one_tab("class Meta:" <> "\n")
    output <> two_tab("db_table = '#{table_name}'" <> "\n")
  end

  # defp filter_primary_key(columns) do
  #   primary = Enum.filter(columns, fn itm -> itm.primary_key end)
  #   col = Enum.filter(columns, fn itm -> !itm.primary_key end)

  #   {primary, col}
  # end

  defp remove_foreign_keys(columns) do
    Enum.filter(columns, fn column ->
      (column.foreign_table == nil and column.foreign_field == nil) or column.primary_key
    end)
  end

  @title_field ["title", "name"]

  defp title_declaration(columns) do
    title_cols = Enum.filter(columns, fn itm -> Enum.member?(@title_field, itm.name) end)

    title =
      case Enum.count(title_cols) > 0 do
        true -> List.first(title_cols).name
        false -> ""
      end

    output = one_tab("def __str__(self):" <> "\n")
    output = output <> two_tab("ret = self.#{title}" <> "\n")
    output <> two_tab("return ret" <> "\n")
  end

  defp escaped_name(name) do
    name
    |> String.replace(" ", "_")
  end

  def type_output({name, type, is_primary_key?}) do
    escaped_name = escaped_name(name)

    type_output_with_source(escaped_name, name, map_type(type), is_primary_key?)
    |> one_tab()
  end

  defp type_output_with_source(escaped_name, escaped_name, mapped_type, true),
    do: "#{escaped_name} = #{mapped_type}(primary_key = True, editable = False)\n"

  defp type_output_with_source(escaped_name, escaped_name, mapped_type, false),
    do: "#{escaped_name} = #{gen_mapped_type(escaped_name, mapped_type)}\n"

  defp gen_mapped_type(field, "models.DateTimeField" = type) do
    cond do
      Enum.member?(@created_time_fields, field) ->
        "#{type}(auto_now_add=True)"

      Enum.member?(@updated_time_fields, field) ->
        "#{type}(auto_now=True)"

      true ->
        "#{type}()"
    end
  end

  defp gen_mapped_type(_field, type), do: "#{type}()"

  defp map_type(:integer), do: "models.IntegerField"
  defp map_type(:decimal), do: "models.DecimalField"
  defp map_type(:float), do: "models.FloatField"
  defp map_type(:string), do: "models.CharField"
  defp map_type(:text), do: "models.CharField"
  defp map_type(:map), do: ":map"
  defp map_type(:date), do: "models.DateTimeField"
  defp map_type(:none), do: ":error"
  defp map_type(:time), do: "models.TimeField"
  defp map_type(:boolean), do: "models.BooleanField"
end
