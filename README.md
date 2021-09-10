# Deterministic Risk
A deterministic, perfect information, version of the turn based Risk game.

# Gameplay Demo
https://user-images.githubusercontent.com/55324331/128356189-93544dfc-31dd-4c47-be5c-fb99d32596bc.mp4

# Game Guide
Deterministic Risk is the game for people who like playing Risk, but can't get a good roll to save their lives.

### Winning:
You win when your opponent has no countries left in their possession.

### Attacking:
Each turn is split into an attack and a reinforce phase. 
Suppose you want to attack country A with country B to conquer it.
This is only possible if B has more units than A, and B is adjacent to A.
Adjacency across oceans is represented with dashed white lines.
After the attack, B is left with 1 unit, and A is left with B-A units.
A is now under your ownership.

### Reinforcing:
The reinforce phase automatically starts when you have no attacks to make or when you click on the "end attack" button. 
During the reinforce phase the number of reinforcements you get is the number of countries you own halved, then rounded up. 

### Controls:
In general:
    Click and drag to pan the map.
During attack:
    Click to select a country that you own.
    Click again to attack a country that you don't own.
During reinforcement:
    Left click to add a reinforcement.
    Right click to remove a reinforcement.
    You cannot remove more reinforcements than you have added.

# Behind the Scenes
The allocation of countries to the blue and red players is done randomly when spawning. However, countries when being spawned, cannot be allocated such that they belong to different players and are adjacent. The player going first gets 3 countries with a unit distribution of [2,2,3]. The player going second gets 4 countries with a unit distribution of [1,2,2,3]. This is to counter the first player advantage.

The number of units in each country is determined randomly at the start of each game. There is a discrete probability distribution behind the randomness but there is no balance or intelligence behind it.  For this reason a **reroll spawn** button is present so that you can reroll the number of units in each country and the allocation of the countries until both players agree that the game is balanced. (1)

# How to Run
Use the standard version of the godot game engine run this game.

Use the mouse 3 button to pan across the map.

https://godotengine.org/download

# Online Connection Guide
This game has no dedicated servers.

If both the host and the guest are not on the same LAN this will not work without a VLAN (eg: Hamachi, ZeroTier).

First the host must be waiting on the level select menu. Only then should the guest enter the IP address and connect. Once the waiting screen shows up on the guest, the host can select a level. Then both the host and guest should have synchronized game screens.

# Future
(1) An AI for single player mode and to help determine the balance of a spawn is in the works.

# Thanks
Thank you to [Allan Ekai](https://github.com/RifleDLuffy) for the 4K images of the maps and help in play testing.
