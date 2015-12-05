require 'YAML'

class GameState
  attr_accessor :player, :monster, :turn_number

  def initialize()
    @turn_number = 0
  end

  def open_game #sets the player
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

  def output_turn (turn_summary)
    #takes in a turn summary and displays the proper text to the user
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

  def change_stats(stat,amount) #to ADD stats, value must be negative
    self.stats[stat] -= amount
  end

  def take_health_hit(value)
    change_stats(:health, value)
  end

  def take_shield_hit(value)
    change_stats(:shield, value)
  end

  def strike(value)
    change_stats(:power, value)
  end

  def regroup
    #rolling for power
    roll = rand(1..3)
    change_stats(:power,-(roll)) #negative roll to add value
    #rolling for shield
    roll = rand(1..3)
    change_stats(:shield,-(roll)) #negative roll to add value
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
  end


  def resolve #resolves the clash
    case move_set1[:action]
    when "a" #When Player 1 attacks
      if move_set2[:action] == "a" #P2 also attacks
        attack_attack(move_set1[:power], move_set2[:power])
      elsif move_set[:action] == "d" #P2 Defends
        attack_defend(move_set1[:power])
      else #P2 regroups - full hit
        self.health_damage = move_set1[:power]
      end
    when "d" #when player 1 defends
      if move_set2[:action] == "a" #P2 also attacks
        attack_defend(-(move_set2[:power])) #negative to ensure shield damage goes to P1
      elsif move_set[:action] == "d" #P2 Defends
        nil #nothing happens
      else #P2 regroups
        self.p2_charge = true
      end
    when "r"
      if move_set2[:action] == "a" #P2 also attacks
        self.health_damage = -(move_set1[:power]) #negative to ensure damage goes to P1
      elsif move_set2[:action] == "d" #P2 Defends
        self.p1_charge=true
      else
        self.p1_charge=true
        self.p2_charge=true
      end
    end
  end

  def attack_attack(power1,power2)
    self.health_damage = power1 - power2 #positive is damage to player 2, negative is damage to player 1
  end

  def attack_defend(attackpower)
    self.shield_damage = attackpower/2
  end
end

class TurnSummary #this generates a turn_summary which can be included in the history of all turns, and can be used to alter the game state
  attr_accessor :summary
  def initialize(player_input, monster_input, damage_type, damage_amount, receiver, recharge_p1, recharge_p2)
    @summary = {
      :damage_type => damage_type, #evaluates to health or shield
      :damage_amount => damage_amount, #the number
      :receiver => receiver, #player one or player two
      :recharge_p1 => recharge_p1, #true or false
      :recharge_p2 => recharge_p2,
      :player_input => player_input,
      :monster_input => monster_input
    }
  end
end

class Turn
  attr_accessor :player_input
  attr_reader :combatant1, :combatant2

  @@Turn_history = []

  def initialize(user,monster)
    @combatant1 = user
    @combatant2 = monster
  end

  def evaluate_move(move) #The method to turn input into a move
    case move.downcase
    when "attack"
      action = "a"
    when "defend"
      action = "d"
    when "regroup"
      action = "r"
    else
      return nil
    end
    power = move.scan(/[A-Z]/).length
    move_set ={
      action: action,
      power: power
    }
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

  def turn_handler(move1,move2)
    #will handle combat and call the appropriate methods on each combatant
    p1_move = evaluate_move(move1) #returns an array with the move in [0] and the power in [1]
    p2_move = evaluate_move(move2)
    #create an instance of clash
  end

end




master = GameState.new()
master.open_game
master.output_state
master.player.regroup
master.output_state

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
