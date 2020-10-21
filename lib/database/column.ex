defmodule Dbmodel.Database.Column do
  defstruct name: "",
            type: "",
            required: false,
            primary_key: false,
            foreign_table: "",
            foreign_field: ""
end
