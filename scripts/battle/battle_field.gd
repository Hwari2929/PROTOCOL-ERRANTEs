extends Node2D
## Battlefield — Planner scaffold (working spawner).
## Spawns a player team and an enemy wave so unit behavior (PE1) is observable.
## PE2 replaces this with roster-based player teams + victory/defeat resolution,
## while PRESERVING the spawn into the "Units" container and the units_of() API.

const UNIT: PackedScene = preload("res://scenes/battle/unit.tscn")

const TEAM_PLAYER: int = 0
const TEAM_ENEMY: int = 1

@onready var units: Node2D = $Units


func _ready() -> void:
	_spawn_team(TEAM_PLAYER, 3, Vector2(380.0, 360.0))
	_spawn_team(TEAM_ENEMY, 4, Vector2(900.0, 360.0))


func _spawn_team(team: int, count: int, origin: Vector2) -> void:
	for i in count:
		var u: Node2D = UNIT.instantiate()
		units.add_child(u)
		var offset: float = (float(i) - float(count - 1) / 2.0) * 84.0
		u.position = origin + Vector2(0.0, offset)
		if u.has_method("setup"):
			u.setup(team)


func units_of(team: int) -> Array:
	var out: Array = []
	for u in units.get_children():
		if u.get("team") == team:
			out.append(u)
	return out
