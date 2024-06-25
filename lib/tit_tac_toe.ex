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
    game = [o: Client.Random, x: Client.Random] |> Game.new |> Game.play
    case game do
      {:ok, game} -> Game.State.inspect(game)
      {:error, error} -> IO.inspect error
    end
  end
end
