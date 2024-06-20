defprotocol Client do
  @spec move(t, String, State) :: {Integer, Integer}
  def move(client, name, game)

  @spec scold(t, Integer, {Integer, Integer}, String) :: nil
  def scold(client, turn, move, error)
end

defmodule Client.Random, do: defstruct []
defimpl Client, for: Client.Random do
  def move(_client, _name, _game), do: {Enum.random(0..2), Enum.random(0..2)}
  def scold(_, _, _, _) do end
end

defmodule Client.Terminal, do: defstruct []
defimpl Client, for: Client.Terminal do
  def move(_client, name, game) do
    Game.State.inspect game
    case Regex.run(~r/^(\d) (\d)\s+$/, IO.gets "#{name}: ") do
      [_, x, y] ->
        [x, y]
        |> Enum.map(&String.to_integer/1)
        |> List.to_tuple
      _ -> nil
    end
  end

  def scold(_client, _turn, move, error), do: IO.puts "#{inspect move} #{error}"
end

defmodule Client.UDP do
  defstruct []

  def new(port \\ 8000) do
    # the agent stores the requesters PID between crashes
    {:ok, _} = Supervisor.start_link(
      [%{id: :client, start: {Client.UDPServer, :start_link, [%{port: port}]}}],
      strategy: :one_for_one)
    %Client.UDP{}
  end
end

defimpl Client, for: Client.UDP do
  def move(_, _, _) do
    GenServer.cast Client.UDPServer, {:get, self()}
    receive do
      [player: _, move: {x, y} = move] ->
        IO.puts "[UDP] got #{inspect move}"
        {x, y}
    end
  end
  def scold(_client, _turn, move, error), do: IO.puts "#{inspect move} #{error}"
end


defmodule Client.UDPServer do
  use GenServer

  defmodule ServerState do
    defstruct ~w[requester move]a
  end

  defp parse_move(data) do
    case data do
      <<_::3, p::1, m::4>> ->
        player = Map.get(%{0 => :x, 1 => :o}, p)
        col = rem(m, 3)
        row = floor(m / 3)
        [player: player, move: {col, row}]
    end
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(%{port: port}) do
    {:ok, _socket} = :gen_udp.open(port, [:binary, active: true])
    {:ok, %ServerState{}}
  end

  def handle_info({:udp, _, _, _, data}, state) do
    move = apply &parse_move/1, [data]
    {:noreply,
     case state do
       %{requester: nil} -> put_in(state.move, move)
       %{requester: from} ->
         send from, move
         %ServerState{}
     end
    }
  end

  def handle_cast({:get, from}, state) do
    {:noreply,
     case state do
       %{move: nil} -> put_in(state.requester, from)
       %{move: move} ->
         send from, move
         %ServerState{}
     end
    }
  end
end
