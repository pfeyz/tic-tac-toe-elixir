defmodule Client do
  @type client_state :: Struct
  @type game_state :: Struct
  @type player_name :: :x | :o

  @callback init(Any, player_name) :: client_state
  @callback move(client_state, player_name, game_state) :: Integer
  @callback ok(client_state, game_state) :: nil
  @callback error(client_state, player_name, String.t()) :: nil
  @callback finish(client_state, player_name, game_state) :: nil

  defmacro __using__(_opts) do
    quote do
      @behaviour Client
      def init(_opts, _name) do nil end
      def ok(_state, _game) do end
      def error(_state, _name, _message) do end
      def finish(_state, _winner, _game) do end

      defoverridable init: 2
      defoverridable ok: 2
      defoverridable error: 3
      defoverridable finish: 3
    end
  end
end


defmodule Client.Random do
  use Client

  def move(nil, _, _),
    do: Enum.random(0..8)
end


defmodule Client.Deterministic do
  use Client

  def init(moves, _) do
    {:ok, agent} = Agent.start_link(fn -> moves end)
    agent
  end

  def move(agent, _, _),
    do: Agent.get_and_update(agent, fn [move | rest] -> {move, rest} end)

end


defmodule Client.Terminal do
  use Client

  def move(nil, name, game) do
    Board.inspect game.board
    case Regex.run(~r/^(\d)\s+$/, IO.gets "#{name}: ") do
      [_, spot] -> spot |> String.to_integer
      _ -> nil
    end
  end

  def ok(nil, game) do
    Board.inspect game.board
    IO.puts "waiting for other player"
  end

  def error(nil, _turn, error),
    do: IO.puts error
end


defmodule Client.UDP do
  use Client
  require Logger

  def random_server_name,
    do: :rand.bytes(16)
    |> :binary.bin_to_list
    |> Enum.map(fn x -> rem(x, 95) + 32 end)

  def init(port \\ 8000) do
    # the agent stores the requesters PID between crashes
    server_name = random_server_name()
    {:ok, _} = Supervisor.start_link(
      [%{id: server_name,
         start: {Server.UDPServer, :start_link, [%{name: server_name, port: port}]}}],
      strategy: :one_for_one)
    server_name
  end

  def move(server, _, _) do
    GenServer.cast server, {:get, self()}
    receive do
      [player: _, move: move] ->
        Logger.debug "Client.UDP got #{inspect move}"
        move
    end
  end

end
