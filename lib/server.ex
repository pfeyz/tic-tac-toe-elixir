defmodule Server.UDPServer do
  require Logger
  use GenServer

  defmodule ServerState do
    defstruct ~w[requester move]a
  end

  defp parse_move(data) do
    case data do
      <<_::3, p::1, move::4>> ->
        player = Map.get(%{0 => :x, 1 => :o}, p)
        [player: player, move: move]
    end
  end

  def start_link(args) do
    {name, args} = pop_in args[:name]
    GenServer.start_link(__MODULE__, args, name: name)
  end

  def init(%{port: port}) do
    {:ok, _socket} = :gen_udp.open(port, [:binary, active: true])
    Logger.info "udp server listening on port #{port}"
    {:ok, %ServerState{}}
  end

  def handle_info({:udp, _, _, _, data}, state) do
    move = apply &parse_move/1, [data]
    {:noreply, case state.requester do
                 # got the move but still waiting for someone to give it to
                 nil -> put_in(state.move, move)
                 from ->
                   send from, move
                   %ServerState{}
               end
    }
  end

  def handle_cast({:get, from}, state) do
    {:noreply, case state.move do
                 # need to wait to actually get the move
                 nil -> put_in(state.requester, from)
                 move ->
                   send from, move
                   %ServerState{}
               end
    }
  end
end
