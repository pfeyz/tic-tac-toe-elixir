
defmodule Game.State do
  @moduledoc """
  Represents the full state of the game.
  """

  @type player :: :x | :o
  @type player_list :: [{Atom, Any}]

  @enforce_keys [:players, :current_turn, :board]
  defstruct [:players, :current_turn, :winner, :board, moves: []]

  @type t :: %__MODULE__{
    players: player_list,
    current_turn: :x | :o,
    winner: nil | :x | :o,
    board: [Board],
    moves: [{Integer, Integer}]
  }

  def inspect(game) do
    IO.puts ""
    IO.write("player: ")
    IO.puts(game.current_turn)
    if game.winner do
      IO.write("winner: ")
      IO.puts(game.winner)
    end
    Board.inspect(game.board)
    IO.puts ""
  end
end
