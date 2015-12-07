require_relative 'planning.rb'

still_playing = true

master = GameState.new()
master.open_game!
while still_playing
  while !(master.game_over) do
    quit = master.conduct_turn
    break if quit
  end
  puts "would you like to play again? (Y/N)"
  answer = gets.chomp
  if answer.downcase == ("y" || "yes")
    master.reset!
  else
    puts "No more songs in your name I guess!"
    still_playing = false
  end
end
