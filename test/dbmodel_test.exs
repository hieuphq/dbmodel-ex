defmodule DbmodelTest do
  use ExUnit.Case
  doctest Dbmodel

  test "greets the world" do
    assert Dbmodel.hello() == :ok
  end
end
