defmodule HTTPillTest do
  use ExUnit.Case
  doctest HTTPill

  test "greets the world" do
    assert HTTPill.hello() == :world
  end
end
