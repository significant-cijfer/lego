defmodule LegoTest do
  use ExUnit.Case
  doctest Lego

  test "greets the world" do
    assert Lego.hello() == :world
  end
end
