defmodule TitTacToeTest do
  use ExUnit.Case
  # doctest TitTacToe

  def test_playthrough(%{players: players, winner: winner, board: board}) do
      players = for {name, moves} <- players,
        do: {name, Client.Deterministic.build(moves)}
      {:ok, game} = players |> Game.new |> Game.play
      assert winner == game.winner
      board_list = game.board |> Board.to_list(:_)
      assert board_list == board
  end

  describe "full playthroughs" do
    test "tie" do
      test_playthrough(%{
        players: [o: [1, 2, 3, 4, 8],
                  x: [0, 5, 6, 7]],
        winner: nil,
        board: ~w[x o o
                  o o x
                  x x o]a
      })
    end

    test "x wins" do
      test_playthrough(%{
        players: [x: [0, 1, 2],
                  o: [3, 4, 5]],
        winner: :x,
        board: ~w[x x x
                  o o _
                  _ _ _]a
      })
    end

    test "o wins" do
      test_playthrough(%{
        players: [x: [1, 2, 3],
                  o: [0, 4, 8]],
        winner: :o,
        board: ~w[o x x
                  x o _
                  _ _ o]a
      })
    end

  end
end
