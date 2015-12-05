require_relative 'planning.rb'

master = GameState.new()
master.open_game!
master.conduct_turn
