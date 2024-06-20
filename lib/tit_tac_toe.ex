defmodule Mix.Tasks.StartGame do
  require Logger
  use Mix.Task

  @moduledoc """
  Documentation for `TitTacToe`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> TitTacToe.hello()
      :world

  """
  def run(_) do
    Logger.configure [level: :info]
    players = [o: %Client.Random{}, x: %Client.Random{}]
    game = Game.play Game.new(players)
    case game do
      {:ok, game} -> Game.State.inspect(game)
      {:error, error} -> IO.inspect error
    end
  end
end
