defmodule Board do
  @moduledoc """

  A board is represented as a map where the keys contain grid locations and the
  values are one of :x, :o or nil.

    iex> Board.new

        %{
            0 => nil,
            1 => nil,
            2 => nil,
            3 => nil,
            4 => nil,
            5 => nil,
            6 => nil,
            7 => nil,
            8 => nil
        }

  iex> Board.new \
  |> Board.put!({0, 0}, :x) \
  |> Board.put!({1, 1}, :x) \
  |> Board.put!({2, 2}, :o) \
  |> Board.inspect

        x . .
        . x .
        . . o
    nil

  """

  @type spot :: [0..8]
  @type board :: %{spot: nil | :x | :o}

  @doc "Creates a new empty board"
  @spec new() :: board
  def new do
    for n <- 0..8, into: %{}, do: {n, nil}
  end

  @doc "Returns true if board has no empty spots left for moves"
  @spec full(board) :: boolean
  def full(board) do
    Enum.empty?(for n <- 0..8, !Map.get(board, n), do: n)
  end

  @doc "Returns nth row in the grid"
  @spec row(board, Integer) :: {Integer, Integer, Integer} | {:error, String.t()}
  def row(_, n) when n < 0 or n > 2 do {:error, n, "row out of range"} end
  def row(board, n) do
    for col <- [0, 1, 2], do: Map.get(board, n * 3 + col)
  end

  @doc "Returns nth column in the grid"
  @spec col(board, Integer) :: {Integer, Integer, Integer} | {:error, String.t()}
  def col(_, n) when n < 0 or n > 2 do {:error, n, "col out of range"} end
  def col(board, n) do
    for row <- [0, 1, 2] do
      Map.get(board, row * 3 + n)
    end
  end

  @doc "Places an :x or :o in the grid coordinate {x, y}"
  @spec put(board, Integer, :x | :o) :: {:ok, board} | {:error, String.t()}
  def put(_, _, value) when value not in [:x, :o] do
    {:error, "player value must be x or o"}
  end

  def put(_, spot, _) when spot < 0 or spot > 8 do
    {:error, "spot is out of range"}
  end

  def put(board, spot, value) do
     if Map.get(board, spot) != nil do
      {:error, "spot already occupied"}
    else
      {:ok, %{board | spot => value}}
    end
  end

  @doc "Prints out the board as an ascii grid"
  @spec inspect(board) :: nil
  def inspect(board) do
    for x <- 0..2 do
      row = for c <- Board.row(board, x) do
        if c do c else '.' end
      end
      IO.puts(Enum.join row, " ")
    end
    nil
  end
end
