defmodule Dbmodel.Config do
  defstruct db: Dbmodel.Config.Database, project: Dbmodel.Config.Project

  def load_configs() do
    load_from_config_exs()
  end

  defp load_from_config_exs() do
    database_config = %Dbmodel.Config.Database{
      host: Application.get_env(:dbmodel, :host, ""),
      port: Application.get_env(:dbmodel, :port, ""),
      dbname: Application.get_env(:dbmodel, :dbname, ""),
      username: Application.get_env(:dbmodel, :username, ""),
      password: Application.get_env(:dbmodel, :password, ""),
      type: Application.get_env(:dbmodel, :type, :postgres)
    }

    project_config = %Dbmodel.Config.Project{
      name: Application.get_env(:dbmodel, :module_name, "Default"),
      output_dir: Application.get_env(:dbmodel, :destination, "")
    }

    %Dbmodel.Config{db: database_config, project: project_config}
  end
end
