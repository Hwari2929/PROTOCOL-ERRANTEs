extends Node2D
## Battle unit — SCAFFOLD STUB. PE1 implements full auto-battle behavior
## (target acquisition, movement, attack-on-cooldown, damage with armor, death).
## Kept minimal so the scaffold compiles and BattleField can spawn units.

var team: int = 0


func setup(unit_team: int) -> void:
	team = unit_team
	add_to_group("unit")
