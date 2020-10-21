defmodule Dbmodel.Database.Pg do
  defstruct host: "localhost",
            port: "5432",
            username: "postgres",
            password: "postgres",
            dbname: "db",
            connection: nil
end

defimpl Dbmodel.Database, for: Dbmodel.Database.Pg do
  @spec create(any, Dbmodel.Config.t()) :: Dbmodel.Database.Pg.t()
  def create(_db, configs) do
    %Dbmodel.Database.Pg{
      host: configs.db.host,
      port: configs.db.port,
      username: configs.db.username,
      password: configs.db.password,
      dbname: configs.db.dbname,
      connection: nil
    }
  end

  @spec connect(Dbmodel.Database.Pg.t()) :: Dbmodel.Database.Pg.t()
  def connect(db) do
    {_, conn} =
      Postgrex.start_link(
        hostname: db.host,
        username: db.username,
        port: db.port,
        password: db.password,
        database: db.dbname
      )

    %Dbmodel.Database.Pg{
      connection: conn,
      host: db.host,
      port: db.port,
      username: db.username,
      password: db.password,
      dbname: db.dbname
    }
  end

  # pass in a database and then get the tables using the Postgrex query then turn the rows into a table
  @spec get_tables(Dbmodel.Database.Pg) :: [Plsm.Database.TableHeader]
  def get_tables(db) do
    {_, result} =
      Postgrex.query(
        db.connection,
        "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';",
        []
      )

    result.rows
    |> List.flatten()
    |> Enum.map(fn x -> %Dbmodel.Database.TableConfig{database: db, name: x} end)
  end

  def get_columns(db, table) do
    {_, result} = Postgrex.query(db.connection, "
          SELECT DISTINCT
            a.attname as column_name,
            format_type(a.atttypid, a.atttypmod) as data_type,
            coalesce(i.indisprimary,false) as primary_key,
            a.attnotnull AS required,
            f.references_table as foreign_table,
            f.references_field as foreign_field,
            a.attnum as num
         FROM pg_attribute a
         JOIN pg_class pgc ON pgc.oid = a.attrelid
         left JOIN (
      	SELECT
      	tc.table_name as table,
      	kcu.column_name as field,
      	ccu.table_name AS references_table,
      	ccu.column_name AS references_field
      	FROM information_schema.table_constraints tc

      	LEFT JOIN information_schema.key_column_usage kcu
      	ON tc.constraint_catalog = kcu.constraint_catalog
      	AND tc.constraint_schema = kcu.constraint_schema
      	AND tc.constraint_name = kcu.constraint_name

      	LEFT JOIN information_schema.referential_constraints rc
      	ON tc.constraint_catalog = rc.constraint_catalog
      	AND tc.constraint_schema = rc.constraint_schema
      	AND tc.constraint_name = rc.constraint_name

      	LEFT JOIN information_schema.constraint_column_usage ccu
      	ON rc.unique_constraint_catalog = ccu.constraint_catalog
      	AND rc.unique_constraint_schema = ccu.constraint_schema
      	AND rc.unique_constraint_name = ccu.constraint_name

      	WHERE lower(tc.constraint_type) in ('foreign key')
        ) as f on a.attname = f.field
        LEFT JOIN pg_index i ON
            (pgc.oid = i.indrelid AND i.indkey[0] = a.attnum)
        WHERE a.attnum > 0 AND pgc.oid = a.attrelid
        AND pg_table_is_visible(pgc.oid)
        AND NOT a.attisdropped
        AND pgc.relname = '#{table.name}'
        ORDER BY a.attnum;", [])

    result.rows
    |> Enum.map(&to_column/1)
  end

  defp to_column(row) do
    {_, name} = Enum.fetch(row, 0)
    type = Enum.fetch(row, 1) |> get_type
    {_, is_required} = Enum.fetch(row, 3)
    {_, foreign_table} = Enum.fetch(row, 4)
    {_, foreign_field} = Enum.fetch(row, 5)
    {_, is_pk} = Enum.fetch(row, 2)

    %Dbmodel.Database.Column{
      name: name,
      type: type,
      primary_key: is_pk,
      required: is_required,
      foreign_table: foreign_table,
      foreign_field: foreign_field
    }
  end

  defp get_type(start_type) do
    {_, type} = start_type
    upcase = String.upcase(type)

    cond do
      String.starts_with?(upcase, "INTEGER") == true -> :integer
      String.starts_with?(upcase, "INT") == true -> :integer
      String.starts_with?(upcase, "BIGINT") == true -> :integer
      String.contains?(upcase, "CHAR") == true -> :string
      String.starts_with?(upcase, "TEXT") == true -> :string
      String.starts_with?(upcase, "FLOAT") == true -> :float
      String.starts_with?(upcase, "DOUBLE") == true -> :float
      String.starts_with?(upcase, "DECIMAL") == true -> :decimal
      String.starts_with?(upcase, "NUMERIC") == true -> :decimal
      String.starts_with?(upcase, "JSONB") == true -> :map
      String.starts_with?(upcase, "DATE") == true -> :date
      String.starts_with?(upcase, "DATETIME") == true -> :date
      String.starts_with?(upcase, "TIMESTAMP") == true -> :date
      String.starts_with?(upcase, "BOOLEAN") == true -> :boolean
      true -> :none
    end
  end
end
