extends Node2D
## Battlefield — roster-based teams + victory/defeat resolution.
## PRESERVES: spawning into $Units, tagging units with team + group "unit",
## and units_of(team) -> Array. Combat-over is detected once and reported via
## EventBus.round_ended(node, victory); BattleSession owns progression, the
## resonance award and the final battle_session_ended signal.

const UNIT: PackedScene = preload("res://scenes/battle/unit.tscn")

const TEAM_PLAYER: int = 0
const TEAM_ENEMY: int = 1

## MAJOR class stat configs (simplest tactical type for the slice).
const ROSTER: Dictionary = {
	"protagonist": {"max_hp": 150, "attack": 14, "attack_interval": 0.9, "attack_range": 120.0, "move_speed": 70.0, "armor": 5},
	"ranger":      {"max_hp": 90,  "attack": 20, "attack_interval": 0.7, "attack_range": 260.0, "move_speed": 60.0, "armor": 1},
	"vanguard":    {"max_hp": 190, "attack": 11, "attack_interval": 1.0, "attack_range": 70.0,  "move_speed": 85.0, "armor": 9},
	"commander":   {"max_hp": 110, "attack": 12, "attack_interval": 0.9, "attack_range": 190.0, "move_speed": 65.0, "armor": 3},
	"medic":       {"max_hp": 100, "attack": 8,  "attack_interval": 1.1, "attack_range": 160.0, "move_speed": 65.0, "armor": 2},
}

const ENEMY_STATS: Dictionary = {"max_hp": 70, "attack": 9, "attack_interval": 1.0, "attack_range": 90.0, "move_speed": 55.0, "armor": 2}

## Player team for the slice: 주인공 + 레인저 + 뱅가드 (exactly 3).
const PLAYER_TEAM_IDS: Array = ["protagonist", "ranger", "vanguard"]

@onready var units: Node2D = $Units

var _resolved: bool = false


func _ready() -> void:
	_spawn_players()
	spawn_wave(4)


func _physics_process(_delta: float) -> void:
	if _resolved:
		return
	if is_over():
		_resolved = true
		var victory: bool = result() == 1
		EventBus.round_ended.emit(1, victory)


## (Re)populate the enemy team for the next combat node.
func spawn_wave(count: int) -> void:
	for e in units_of(TEAM_ENEMY):
		e.queue_free()
	for i in count:
		var u: Node2D = _make_unit(TEAM_ENEMY, ENEMY_STATS)
		var offset: float = (float(i) - float(count - 1) / 2.0) * 84.0
		u.position = Vector2(900.0, 360.0 + offset)
	_resolved = false


func _spawn_players() -> void:
	var n: int = PLAYER_TEAM_IDS.size()
	for i in n:
		var id: String = PLAYER_TEAM_IDS[i]
		var cfg: Dictionary = ROSTER[id]
		var u: Node2D = _make_unit(TEAM_PLAYER, cfg)
		var offset: float = (float(i) - float(n - 1) / 2.0) * 90.0
		u.position = Vector2(380.0, 360.0 + offset)


## Spawn one unit, tag its team/group, and apply stats dynamically.
## unit.gd has no class_name, so its script vars are assigned via set().
func _make_unit(team: int, cfg: Dictionary) -> Node2D:
	var u: Node2D = UNIT.instantiate()
	units.add_child(u)
	if u.has_method("setup"):
		u.setup(team)
	for key in cfg:
		u.set(key, cfg[key])
	u.set("hp", int(cfg.get("max_hp", 100)))
	return u


## Living units of a team.
func units_of(team: int) -> Array:
	var out: Array = []
	for u in units.get_children():
		if is_instance_valid(u) and int(u.get("team")) == team and int(u.get("hp")) > 0:
			out.append(u)
	return out


func is_over() -> bool:
	return units_of(TEAM_PLAYER).is_empty() or units_of(TEAM_ENEMY).is_empty()


## 0 = ongoing, 1 = victory (enemies cleared, players remain), -1 = defeat.
func result() -> int:
	var players: Array = units_of(TEAM_PLAYER)
	var enemies: Array = units_of(TEAM_ENEMY)
	if players.is_empty():
		return -1
	if enemies.is_empty():
		return 1
	return 0
