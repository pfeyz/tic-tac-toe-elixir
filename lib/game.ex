defmodule Game do
  require Logger
  alias Game.State

  @type move :: [0..8]
  @type t :: Game.State.t()

  defp init_player(player, name) when is_atom(player) do
    {player, player.init(nil, name)}
  end

  defp init_player({player, arg}, name) do
    {player, player.init(arg, name)}
  end

  @spec new(Game.State.player_list) :: Game.State
  def new(players) do
    starter = players |> Keyword.keys |> List.first
    players = for {name, p} <- players, do: {name, init_player(p, name)}, into: %{}
    %State{players: players,
           current_turn: starter,
           winner: nil,
           moves: [],
           board: Board.new}
  end

  @spec play_turn(t, move) :: {:ok, t}, {:end, t} | {:error, String.t()}
  def play_turn(game, move) do
    case make_move game, move do
      {:error, error} -> {:error, error}
      {:ok, game} -> case Game.goal? game do
                       {:winner, winner} -> {:end, %{game | winner: winner}}
                       :full -> {:end, game}
                       _  -> {:ok, game}
                     end
    end
  end

  @spec play(t) :: {:ok, t} | {:error, String.t()}
  def play(game) do
    turn = game.current_turn
    Logger.debug "waiting for move from player #{turn}"
    {client, state} = game.players[turn]
    case client.move(state, turn, game) do

      move when is_integer(move) ->
        case play_turn game, move do
          {:error, error} ->
            Logger.debug "got unpermitted move #{inspect move} from #{turn}: \"#{error}\""
            client.error(state, turn, error)
            play game
          {:ok, game} ->
            Logger.debug "got legal move #{inspect move} from #{turn}"
            client.ok(state, game)
            play game
          {:end, game} ->
            for {_, {client, state}} <- Map.to_list(game.players) do
              client.finish(state, game.winner, game)
            end
            {:ok, game}
        end

      move ->
        Logger.debug("got illegal move #{inspect move} from #{turn}")
        client.error(state, turn, "invalid move")
        play game

    end
  end

  @spec make_move(t, move) :: {:ok, t} | {:error, String.t()}
  def make_move(game, move) do
    case Board.put game.board, move, game.current_turn do
      {:error, message} -> {:error, message}
      {:ok, board} -> {:ok, game
      |> Map.put(:moves, [move | game.moves])
      |> Map.put(:board, board)
      |> Map.put(:current_turn, if game.current_turn == :x do :o else :x end)
      }
    end
  end

  @spec winning_path?([:x | :o | nil, ...]) :: boolean
  def winning_path?(path) do
    Enum.reduce path, fn(x, acc) ->
      if x == acc do acc else nil end
    end
  end

  @spec goal?(t) :: {:winner, State.player} | :full | nil
  def goal?(game) do
    board = game.board
    paths = for n <- 0..2 do Board.row(board, n) end
    ++ for n <- 0..2 do Board.col(board, n) end
    paths = paths ++ [for n <- [0, 4, 8] do Map.get(board, n) end,
                      for n <- [2, 4, 6] do Map.get(board, n) end
                     ]
    wins = Enum.map paths, fn a -> Game.winning_path?(a) end
    found_winner = Enum.reduce wins, fn x, acc -> x || acc end
    if found_winner do
      {:winner, found_winner}
    else
      if Board.full(board), do: :full
    end
  end

end
