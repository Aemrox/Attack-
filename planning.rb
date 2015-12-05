require 'YAML'
require 'pry'

class GameState
  attr_accessor :player, :monster, :turn_number

  def initialize()
    @turn_number = 0
  end

  def open_game! #sets the player
    puts "WELCOME TO__________________________________________________________
             _____      ______) ______) _____   )   ___    __   __) /
            (, /  |    (, /    (, /    (, /  | (__/_____) (, ) /   /
              /---|      /       /       /---|   /          /(    /
           ) /    |_  ) /     ) /     ) /    |_ /        ) /  \_ o
          (_/        (_/     (_/     (_/       (______) (_/
                                                                      "
    puts "Create your character by giving him or her a name:"
    name = gets.chomp
    self.player = User.new(name)
    puts "Welcome #{player.name}!"
    new_enemy
  end

  def conduct_turn
    #creates and resolves a turn
    output_state
    this_turn = Turn.new
    sleep(1)
    #monster_input = self.enemy_AI #This is where the monster's move is determined
    this_turn.run_turn!("attack")
    alter_game_state(this_turn.summary)
  end

  def alter_game_state! (turn_summary)
    # Here is the structure of a turn_summary for reference
    # @summary = {
    #   :damage_type => damage_type, #evaluates to :health or :shield
    #   :damage_amount => damage_amount, #the number
    #   :receiver => receiver, #player or monster
    #   :recharge_player => recharge_player, #true or false
    #   :recharge_monster => recharge_monster,
    #   :player_input => player_input, #still hash with :action and :power as keys
    #   :monster_input => monster_input
    # }

    #output the choices
    puts "#{player.name} chose to #{turn_summary[:player_input]}"
    puts "#{monster.name} chose to #{turn_summary[:monster_input]}"

    #part 2 depleting the power from actions
    player.strike!(turn_summary[:player_input][:power]) if turn_summary[:player_input][:action] == "attack"
    monster.strike!(turn_summary[:monster_input][:power]) if turn_summary[:monster_input][:action] == "attack"

    #part 3 dealing with damage
    if turn_summary[:receiver] == "monster"
      #deal with monster damage
      if turn_summary[:damage_type] == :shield #shield damage
        monster.take_shield_hit!(turn_summary[:damage])
      elsif turn_summary[:damage_type] == :health #health damage
        monster.take_health_hit!(turn_summary[:damage])
      end
    elsif turn_summary[:receiver] == "player"
      #deal with player damage
      if turn_summary[:damage_type] == :shield #shield damage
        player.take_shield_hit!(turn_summary[:damage])
      elsif turn_summary[:damage_type] == :health #health damage
        player.take_health_hit!(turn_summary[:damage])
      end
    end

    #part 4 checking for regroup
    player.regroup! if turn_summary[:recharge_player]
    monster.regroup! if turn_summary[:monster_recharge]

  end

  def output_state
    #outputs current game state i.e. User and Monster health, shield, power, and turn number
    puts "It is turn #{turn_number}
    #{player.name} - Health:#{player.health} Shield:#{player.shield} Power:#{player.power}
    #{monster.name} - Health:#{monster.health} Shield:#{monster.shield} Power:#{monster.power}
    "
  end

  private
  def enemy_AI #this method is the decision engine for picking an enemy move
    #it examines the game state and makes returns a move decision
    #will write a very basic decision matrix, and will elaborate as I play the
    #game and learn the nuances of the rules
    #I WOULD WELCOME ANY INPUT HERE
  end

  def new_enemy#instantiates a new enemy
    monster_names = YAML.load_file("./monster.yml")
    self.monster = User.new(monster_names.sample)
    puts "You are facing a vicious #{monster.name}"
    sleep(1)
  end

end

class User
  attr_accessor :name,:stats,:record  # => nil

  #Init will name the char and give basic stats
  def initialize(name)
    @name = name
    #default statistics
    @stats = {
      :health => 5,
      :power => 5,
      :shield => 5
    }

  end

  def change_stats!(stat,amount) #to ADD stats, value must be negative
    self.stats[stat] -= amount
  end

  def take_health_hit!(value)
    change_stats(:health, value)
    puts "#{name} took #{value} damage to their health!"
  end

  def take_shield_hit!(value)
    change_stats(:shield, value)
    puts "#{name} defended and took #{value} damage to their shield!"
  end

  def strike!(value)
    change_stats(:power, value)
    puts "#{name} struck for #{value} damage!"
  end

  def regroup!
    #rolling for power
    roll = rand(1..3)
    change_stats(:power,-(roll)) #negative roll to add value
    #rolling for shield
    roll2 = rand(1..3)
    change_stats(:shield,-(roll2)) #negative roll to add value
    puts "#{name} regrouped and recovered #{roll} power and #{roll2} shield"
  end

  def health
    stats[:health]
  end

  def power
    stats[:power]
  end

  def shield
    stats[:shield]
  end

end

class Clash
  attr_reader :input_1, :input_2
  attr_accessor :shield_damage, :health_damage, :p1_charge, :p2_charge
  #in general, positive damage is to player 2 and negative damage is to player 1

  def initialize(p1_move,p2_move)
    @input_1 = p1_move
    @input_2 = p2_move
    @p1_charge = false
    @p2_charge = false
    @shield_damage = 0
    @health_damage = 0
  end


  def resolve! #resolves the clash
    binding.pry
    case input_1[:action]
    when "attack" #When Player 1 attacks
      binding.pry
      if input_2[:action] == "attack" #P2 also attacks
        attack_attack(input_1[:power], input_2[:power])
      elsif input_2[:action] == "defend" #P2 Defends
        attack_defend(input_1[:power])
      else #P2 regroups - full hit
        self.health_damage = input_1[:power]
      end
    when "defend" #when player 1 defends
      binding.pry
      if input_2[:action] == "attack" #P2 also attacks
        attack_defend(-(input_2[:power])) #negative to ensure shield damage goes to P1
      elsif input_2[:action] == "defend" #P2 Defends
        nil #nothing happens
      else #P2 regroups
        self.p2_charge = true
      end
    when "regroup"
      if input_2[:action] == "attack" #P2 also attacks
        self.health_damage = -(input_1[:power]) #negative to ensure damage goes to P1
      elsif input_2[:action] == "defend" #P2 Defends
        self.p1_charge=true
      else
        self.p1_charge=true
        self.p2_charge=true
      end
    end
  end

  def create_turn_summary #resolves and turns a summary of the turn
    self.resolve! #resolve the clash

    #determine what type of damage is dealt
    if !(health_damage == 0)
      damage_type = :health
      damage = health_damage
    elsif !(shield_damage == 0)
      damage_type = :shield
      damage = shield_damage
    else
      damage_type = nil
      damage = 0
    end

    #determine receiver (to whom the damage is dealt)
    if damage < 0
      receiver = "player"
    elsif damage > 0
      receiver = "monster"
    else
      receiver = nil
    end

    #making sure damage is positive
    damage = damage.abs

    #finally create summary
    turn_sum = TurnSummary.new(input_1, input_2, damage_type, damage, receiver, p1_charge, p2_charge)
  end

  private
  def attack_attack(power1,power2)
    self.health_damage = power1 - power2 #positive is damage to player 2, negative is damage to player 1
  end

  def attack_defend(attackpower)
    self.shield_damage = attackpower/2
  end
end

class TurnSummary #this generates a turn_summary which can be included in the history of all turns, and can be used to alter the game state
  attr_accessor :summary
  def initialize(player_input, monster_input, damage_type, damage_amount, receiver, recharge_player, recharge_monster)
    @summary = {
      :damage_type => damage_type, #evaluates to :health or :shield
      :damage_amount => damage_amount, #the number
      :receiver => receiver, #player or monster or nil for no damage
      :recharge_player => recharge_player, #true or false
      :recharge_monster => recharge_monster,
      :player_input => player_input, #still hash with :action and :power as keys
      :monster_input => monster_input
    }
  end
end

class Turn
  attr_accessor :player_input, :summary

  @@Turn_history = []

  def initialize()
  end

  def run_turn!(monster_input)
    self.player_input = get_input
    this_clash = Clash.new(evaluate_move(player_input),monster_input)
    summary = this_clash.create_turn_summary
    add_turn(summary)
  end

  def action_list
    #displays list of potential actions
    puts "Welcome to ATTACK! training
    You are facing off aginst a vicious opponent, but fear not!
    You have a slew of tools at your disposal:
    Your Health shows how many hit points you have remaining.
    Your Shield shows how many blows you can still absorb while defending.
    Your Power shows how many attack points you have.

    You can choose to 'attack', 'defend', or 'regroup'.
    Attacking expends power points to damage your opponent
    - but take Note! you determine the power of your attack by how many capital letters you use!
    Defending guards against attack at the expense of shield points
    Regrouping restores a random amount of attack and defense points, but leaves you open to attack!

    Now onwards! To Battle! ATTACK!!!!!
    "
  end

  private
  def evaluate_move(move) #The method to turn input into a move
    action = move.downcase
    power = move.scan(/[A-Z]/).length
    move_set ={
      action: action,
      power: power
    }
  end

  def add_turn(summary)#takes in a turn summary and adds it to the history
    @summary = summary
    @@Turn_history << summary
  end

  def action_list
    #displays list of potential actions
    puts "Welcome to ATTACK! training
    You are facing off aginst a vicious opponent, but fear not!
    You have a slew of tools at your disposal:
    Your Health shows how many hit points you have remaining.
    Your Shield shows how many blows you can still absorb while defending.
    Your Power shows how many attack points you have.

    You can choose to 'attack', 'defend', or 'regroup'.
    Attacking expends power points to damage your opponent
    - but take Note! you determine the power of your attack by how many capital letters you use!
    Defending guards against attack at the expense of shield points
    Regrouping restores a random amount of attack and defense points, but leaves you open to attack!

    Now onwards! To Battle! ATTACK!!!!!
    "
  end

  def get_input #recieves input from the user, validates and returns
    puts "The move is yours: (type 'help' for training)"
    input = gets.chomp
    if input == "help"
      action_list
      return get_input
    elsif (input.downcase == ("attack" || "defend" || "regroup"))
      return input
    else
      puts ("That's not a real move! type 'help' for training")
      return get_input
    end
  end
end


#Rule base for the game

#PVE - you pick an action, copmuter responds with AI action
#PVP - two people pick an action and submit at once

#List of stats
#Health
# => Hit Points, you die when 0 (for now starts at X)
#Shield
# => your defense, gets used when you use defense
#Power
# => like PP in pokemon, gets used up when you attack

#List of Actions
#attack -
# => an attack whose power (and refractory period) is defined by
# => the amount number of capitals
#defend -
# => nullfies an attack at the expense of your shield
#regroup -
# => recharges your defense OR attack points based your previous action
