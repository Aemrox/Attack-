require_relative 'planning.rb'

master = GameState.new()
master.open_game
master.output_state
master.player.regroup
master.output_state
