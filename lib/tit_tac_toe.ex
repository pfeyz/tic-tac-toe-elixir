defmodule Mix.Tasks.StartGame do
  require Logger
  use Mix.Task

  @moduledoc """
  Documentation for `TicTacToe`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> TicTacToe.hello()
      :world

  """
  def run(args) do
    Logger.configure [level: :debug]


    player_map = %{
      "rand" => Client.Random,
      "term" => Client.Terminal,
      "udp"  => Client.UDP
    }

    args = case args do
         [] -> ["rand", "rand"]
         args -> args
    end
    
    [px, po] = Enum.map(args, fn name -> Map.fetch!(player_map, name)  end)

    game = [x: px, o: po] |> Game.new |> Game.play
    case game do
      {:ok, game} -> Game.State.inspect(game)
      {:error, error} -> IO.inspect error
    end
  end
end
