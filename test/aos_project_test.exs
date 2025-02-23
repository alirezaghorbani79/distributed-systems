defmodule AosProjectTest do
  use ExUnit.Case
  doctest AosProject

  test "greets the world" do
    assert AosProject.hello() == :world
  end
end
