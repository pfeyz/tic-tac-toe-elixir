# TicTacToe

A simple tic tac toe game in elixir.

To see two random players play against each other, run:

    mix start_game
    
or you can specify two differnet players types to pit against each other, choosing from

  - rand: a random move player
  - term: an interactive player providing moves via the terminal
  - udp: a player that will send moves via udp packets
  
for example, to make player X play via the terminal and player O play via udp:

    mix start_game term udp
