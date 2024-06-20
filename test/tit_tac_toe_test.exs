defmodule TitTacToeTest do
  use ExUnit.Case
  doctest TitTacToe

  test "greets the world" do
    assert TitTacToe.hello() == :world
  end
end
