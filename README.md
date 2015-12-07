ATTACK! 0.1

This is a very basic version of my first side project ATTACK.

It's modeled after an old school yard game I used to play.

run runner.rb in order to play the game!


VERSION 0.1
This particular version is missing the enemy AI, so there is no real challenge. The enemy performs the same move every time (weak attack).

The next step for me is to build the enemy AI. From there I'd like to develop a different monsters with different stats (which would affect AI).

Eventually, as we learn more things, I'd like to build the game out - perhaps make a progression, saving experience and characters, or even build out a multi-player.

THE REASONING

I built this in an effort to cement what we learned over the weak, and as an exercise in building something larger using some of the object oriented design principles we learned towards the end of the week.

Keeping track of multiple objects and managing the development of many moving parts proved to be pretty difficult. It required having far more planning and organization than I originally thought.

THE RULES

The game pits you against a randomly generated monster (all have the same base statistics). From there you have three options, to Attack, Defend, or Regroup.

Attacking is a dynamic move, whose power is determined by the number of capital letters used to type out the word attack. Attacking consumes power points (again the number of capital letters used)

Defending defends against attack, but consumes shield points.

Regrouping uses a random roll to recharge power and shield points.

When both sides attack, the side with the higher power does damage equal to the difference. When someone defends an attack, they lose shield points equal to half the power.

When a player regroups, he absorbs the full strength of an attack. A player who regroups without being attacked recovers more shield and power points.

The game ends when health reaches zero.



Places I'd like to go in the future

  Saving characters - and keeping records of wins/losses
  Different monsters
  Levels of difficulty based around an expanded AI and different monster_names
  Player V Player - which requires LAN or internet based connections between clients (much more advanced)
