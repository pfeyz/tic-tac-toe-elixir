defmodule Game do
  require Logger
  alias Game.State

  @type move :: [0..8]
  @type t :: Game.State.t()

  @spec new(Game.State.player_list) :: Game.State
  def new(players), do: %State{players: players,
                               current_turn: players |> Keyword.keys |> List.first,
                               winner: nil,
                               moves: [],
                               board: Board.new}

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
    player = game.players[turn]
    Logger.debug "waiting for move from player #{turn}"
    case Client.move player, turn, game do

      move when is_integer(move) ->
        case play_turn game, move do
          {:error, error} ->
            Logger.debug "got unpermitted move #{inspect move} from #{turn}: \"#{error}\""
            Client.scold player, turn, move, error
            play game
          {:ok, game} ->
            Logger.debug "got legal move #{inspect move} from #{turn}"
            # Board.inspect game.board
            play game
          {:end, game} -> {:ok, game}
        end

      move ->
        Logger.debug("got illegal move #{inspect move} from #{turn}: #{move}")
        Client.scold(player, turn, move, "invalid move")
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
