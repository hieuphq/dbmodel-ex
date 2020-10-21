defmodule Dbmodel.IO.Export do
  @doc """
    Generate the schema field based on the database type
  """
  @ignore_fields ["created_at", "updated_at", "deleted_at", "inserted_at"]

  def type_output({name, type, is_primary_key?}) do
    escaped_name = escaped_name(name)

    type_output_with_source(escaped_name, name, map_type(type), is_primary_key?)
    |> four_space()
  end

  defp map_type(:integer), do: ":integer"
  defp map_type(:decimal), do: ":decimal"
  defp map_type(:float), do: ":float"
  defp map_type(:string), do: ":string"
  defp map_type(:text), do: ":string"
  defp map_type(:map), do: ":map"
  defp map_type(:date), do: ":naive_datetime"
  defp map_type(:none), do: ":error"
  defp map_type(:boolean), do: ":boolean"

  # When escaped name and name are the same, source option is not needed
  defp type_output_with_source(escaped_name, escaped_name, mapped_type, true),
    do: "field(:#{escaped_name}, #{mapped_type}, primary_key: #{true})\n"

  defp type_output_with_source(escaped_name, escaped_name, mapped_type, false),
    do: "field(:#{escaped_name}, #{mapped_type})\n"

  # When escaped name and name are different, add a source option poitning to the original field name as an atom
  defp type_output_with_source(escaped_name, name, mapped_type, true),
    do: "field(:#{escaped_name}, #{mapped_type}, primary_key: #{true}, source: :\"#{name}\")\n"

  defp type_output_with_source(escaped_name, name, mapped_type, false),
    do: "field(:#{escaped_name}, #{mapped_type}, source: :\"#{name}\")\n"

  @doc """
    Write the given schema to file.
  """
  @spec write(String.t(), String.t(), String.t()) :: Any
  def write(schema, name, path \\ "") do
    case File.open("#{path}#{name}.ex", [:write]) do
      {:ok, file} ->
        IO.puts("#{path}#{name}.ex")
        IO.binwrite(file, schema)
        File.close(file)

      {_, msg} ->
        IO.puts("Could not write #{name} to file: #{msg}")
    end
  end

  defp filter_primary_key(columns) do
    primary = Enum.filter(columns, fn itm -> itm.primary_key end)
    col = Enum.filter(columns, fn itm -> !itm.primary_key end)

    {primary, col}
  end

  @doc """
  Format the text of a specific table with the fields that are passed in. This is strictly formatting and will not verify the fields with the database
  """
  @spec prepare(Dbmodel.Database.Table.t(), String.t()) :: {String.t(), String.t()}
  def prepare(table, project_name) do
    columns = table.columns
    {primary, cols} = filter_primary_key(columns)

    output =
      module_declaration(project_name, table.name) <>
        model_inclusion() <> schema_declaration(table.name, primary)

    trimmed_columns = remove_foreign_keys(cols)

    column_output =
      trimmed_columns
      |> Enum.reduce("", fn column, a ->
        a <> type_output({column.name, column.type, column.primary_key})
      end)

    output = output <> column_output

    belongs_to_output =
      Enum.filter(columns, fn column ->
        column.foreign_table != nil and column.foreign_table != nil
      end)
      |> Enum.reduce("", fn column, a ->
        a <> belongs_to_output(project_name, column)
      end)

    output = output <> belongs_to_output <> "\n"
    output = output <> two_space(end_declaration()) <> "\n"
    output = output <> gen_required_fields(cols, @ignore_fields) <> "\n"
    output = output <> gen_optional_fields(cols, @ignore_fields) <> "\n\n"
    output = output <> gen_changeset(columns) <> end_declaration()
    output <> end_declaration()
    {table.name, output}
  end

  defp gen_changeset(_colums) do
    output = two_space("def changeset(struct, params \\\\ %{}) do\n")
    output = output <> four_space("struct\n")
    output = output <> four_space("|> cast(params, [@required_fields ++ @optional_fields])\n")
    output <> two_space("end\n")
  end

  defp gen_optional_fields(columns, except_columns) do
    columns
    |> Enum.filter(fn itm -> !itm.required && !Enum.member?(except_columns, itm.name) end)
    |> do_gen_required_fields("optional_fields")
  end

  defp gen_required_fields(columns, except_columns) do
    columns
    |> Enum.filter(fn itm -> itm.required && !Enum.member?(except_columns, itm.name) end)
    |> do_gen_required_fields("required_fields")
  end

  defp do_gen_required_fields(cols, title) do
    col_string =
      cols
      |> Enum.map(fn itm -> ":#{itm.name}" end)
      |> Enum.join(", ")

    two_space("@#{title} ~w(#{col_string})a")
  end

  defp module_declaration(project_name, table_name) do
    namespace = Dbmodel.Database.Table.table_name(table_name)
    "defmodule #{project_name}.#{namespace} do\n"
  end

  defp model_inclusion do
    two_space("use Ecto.Schema\n" <> two_space("import Ecto.Changeset\n\n"))
  end

  defp schema_declaration(table_name, primary) when is_nil(primary) do
    gen_schema_declaration(table_name, nil, :none)
  end

  defp schema_declaration(table_name, primary) when length(primary) > 0 do
    pri = List.first(primary)
    gen_schema_declaration(table_name, pri.name, pri.type)
  end

  defp gen_schema_declaration(table_name, nil, _) do
    output = two_space("@primary_key false\n")
    output <> two_space("schema \"#{table_name}\" do\n")
  end

  defp gen_schema_declaration(table_name, "id", _type) do
    two_space("schema \"#{table_name}\" do\n")
  end

  defp gen_schema_declaration(table_name, primary_key, type) do
    pri_type = primary_type_string(type)

    pri_type_str =
      case pri_type do
        "" -> ""
        type -> ", :#{type}"
      end

    output = two_space("@primary_key {:#{primary_key}#{pri_type_str}}\n")
    output <> two_space("schema \"#{table_name}\" do\n")
  end

  defp primary_type_string(:integer), do: "id"
  defp primary_type_string(:string), do: "binary_id"
  defp primary_type_string(_), do: ""

  defp end_declaration do
    "end\n"
  end

  defp four_space(text \\ "") do
    "    " <> text
  end

  defp six_space(text) do
    "      " <> text
  end

  defp two_space(text) do
    "  " <> text
  end

  defp changeset(columns) do
    output = two_space("def changeset(struct, params \\\\ %{}) do\n")
    output = output <> four_space("struct\n")
    output = output <> four_space("|> cast(params, [" <> changeset_list(columns) <> "])\n")
    output <> two_space("end\n")
  end

  defp changeset_list(columns) do
    out =
      columns
      |> Enum.map(fn c -> six_space(":#{escaped_name(c.name)}") end)
      |> Enum.join(",\n")

    if out != "", do: "\n" <> out <> "\n" <> four_space(), else: out
  end

  @spec prepare(String.t(), Dbmodel.Database.Column) :: String.t()
  defp belongs_to_output(project_name, column) do
    column_name = column.name |> String.trim_trailing("_id")
    table_name = Dbmodel.Database.Table.table_name(column.foreign_table)
    "\n" <> four_space("belongs_to(:#{column_name}, #{project_name}.#{table_name})")
  end

  defp remove_foreign_keys(columns) do
    Enum.filter(columns, fn column ->
      column.foreign_table == nil and column.foreign_field == nil
    end)
  end

  defp escaped_name(name) do
    name
    |> String.replace(" ", "_")
  end
end
