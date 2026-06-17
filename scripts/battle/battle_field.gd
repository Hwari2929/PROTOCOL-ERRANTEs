extends Node2D
## Battlefield — roster-based teams + victory/defeat resolution.
## PRESERVES: spawning into $Units, tagging units with team + group "unit",
## and units_of(team) -> Array. Combat-over is detected once and reported via
## EventBus.round_ended(node, victory); BattleSession owns progression, the
## resonance award and the final battle_session_ended signal.

const UNIT: PackedScene = preload("res://scenes/battle/unit.tscn")

const TEAM_PLAYER: int = 0
const TEAM_ENEMY: int = 1

## Phase constants
const PHASE_PREP: int = 0
const PHASE_COMBAT: int = 1

## MAJOR class stat configs (simplest tactical type for the slice).
const ROSTER: Dictionary = {
	"protagonist": {"max_hp": 150, "attack": 14, "attack_interval": 0.9, "attack_range": 120.0, "move_speed": 70.0, "armor": 5},
	"ranger":      {"max_hp": 90,  "attack": 20, "attack_interval": 0.7, "attack_range": 260.0, "move_speed": 60.0, "armor": 1},
	"vanguard":    {"max_hp": 190, "attack": 11, "attack_interval": 1.0, "attack_range": 70.0,  "move_speed": 85.0, "armor": 9},
	"commander":   {"max_hp": 110, "attack": 12, "attack_interval": 0.9, "attack_range": 190.0, "move_speed": 65.0, "armor": 3},
	"medic":       {"max_hp": 100, "attack": 8,  "attack_interval": 1.1, "attack_range": 160.0, "move_speed": 65.0, "armor": 2},
}

const ENEMY_STATS: Dictionary = {"max_hp": 70, "attack": 9, "attack_interval": 1.0, "attack_range": 90.0, "move_speed": 55.0, "armor": 2}
## Faster, frailer 군체 variant (introduced from node 2).
const SWARMLING_STATS: Dictionary = {"max_hp": 45, "attack": 7, "attack_interval": 0.8, "attack_range": 80.0, "move_speed": 95.0, "armor": 0}
## Boss (final node): a large, durable 군체 brood-mother.
const BOSS_STATS: Dictionary = {"max_hp": 680, "attack": 22, "attack_interval": 1.3, "attack_range": 120.0, "move_speed": 46.0, "armor": 9, "body_scale": 2.0}
## Final node index (a boss wave instead of a normal wave).
const BOSS_NODE: int = 3

## Player team for the slice: 주인공 + 레인저 + 뱅가드 (exactly 3).
const PLAYER_TEAM_IDS: Array = ["protagonist", "ranger", "vanguard"]

@onready var units: Node2D = $Units

var _resolved: bool = false
var phase: int = PHASE_PREP

signal phase_changed(new_phase: int)


func _ready() -> void:
	_spawn_players()
	spawn_wave(1)
	begin_prep()


func _physics_process(_delta: float) -> void:
	if _resolved:
		return
	if phase != PHASE_COMBAT:
		return
	if is_over():
		_resolved = true
		var victory: bool = result() == 1
		EventBus.round_ended.emit(1, victory)


## (Re)populate the enemy team for a given 1-based NODE INDEX.
## Count and stats scale with the node; a faster swarmling variant joins from node 2.
func spawn_wave(node_index: int) -> void:
	for e in units.get_children():
		if is_instance_valid(e) and e.is_in_group("unit") and int(e.get("team")) == TEAM_ENEMY:
			e.queue_free()
	if node_index >= BOSS_NODE:
		_spawn_boss_wave()
	else:
		_spawn_normal_wave(node_index)
	_resolved = false
	begin_prep()


func _spawn_normal_wave(node_index: int) -> void:
	var count: int = 3 + node_index
	var stat_scale: float = 1.0 + 0.25 * float(node_index - 1)
	for i in count:
		var is_fast: bool = node_index >= 2 and i % 3 == 2
		var cfg: Dictionary = (SWARMLING_STATS if is_fast else ENEMY_STATS).duplicate()
		cfg["max_hp"] = int(round(float(cfg["max_hp"]) * stat_scale))
		cfg["attack"] = int(round(float(cfg["attack"]) * stat_scale))
		var u: Node2D = _make_unit(TEAM_ENEMY, cfg, "swarm")
		var offset: float = (float(i) - float(count - 1) / 2.0) * 84.0
		u.position = Vector2(900.0, 360.0 + offset)


## Final node: one big boss flanked by two swarm minions.
func _spawn_boss_wave() -> void:
	var boss: Node2D = _make_unit(TEAM_ENEMY, BOSS_STATS.duplicate(), "swarm")
	boss.position = Vector2(930.0, 360.0)
	for i in 2:
		var u: Node2D = _make_unit(TEAM_ENEMY, ENEMY_STATS.duplicate(), "swarm")
		u.position = Vector2(840.0, 360.0 + (-1.0 if i == 0 else 1.0) * 150.0)


func _spawn_players() -> void:
	_spawn_player_ids(PLAYER_TEAM_IDS)


## Rebuild the player team from a list of roster ids (used by team selection).
## Invalid/empty selections fall back to the default trio.
func set_player_team(ids: Array, subclasses: Dictionary = {}) -> void:
	for u in units.get_children():
		if is_instance_valid(u) and u.is_in_group("unit") and int(u.get("team")) == TEAM_PLAYER:
			u.queue_free()
	var valid: Array = []
	for id in ids:
		if ROSTER.has(id) and not valid.has(id):
			valid.append(id)
	if valid.is_empty():
		valid = PLAYER_TEAM_IDS
	_spawn_player_ids(valid, subclasses)
	EventBus.team_changed.emit(valid)
	begin_prep()


func _spawn_player_ids(ids: Array, subclasses: Dictionary = {}) -> void:
	var n: int = ids.size()
	for i in n:
		var id: String = ids[i]
		var cfg: Dictionary = ROSTER[id]
		var u: Node2D = _make_unit(TEAM_PLAYER, cfg, id)
		# Override the default subclass with the player's choice (tiers apply later).
		if subclasses.has(id) and String(subclasses[id]) != "":
			u.set("subclass_id", subclasses[id])
		var offset: float = (float(i) - float(n - 1) / 2.0) * 90.0
		u.position = Vector2(380.0, 360.0 + offset)


## Spawn one unit, tag its team/group, and apply stats dynamically.
## unit.gd has no class_name, so its script vars are assigned via set().
func _make_unit(team: int, cfg: Dictionary, sprite_id: String = "") -> Node2D:
	var u: Node2D = UNIT.instantiate()
	units.add_child(u)
	if u.has_method("setup"):
		u.setup(team)
	for key in cfg:
		u.set(key, cfg[key])
	u.set("hp", int(cfg.get("max_hp", 100)))
	u.set("sprite_id", sprite_id)
	if u.has_method("refresh_sprite"):
		u.refresh_sprite()
	# Class identity: default subclass + base inhesion (player classes only).
	if ClassData.has_class(sprite_id):
		if String(u.get("subclass_id")) == "":
			u.set("subclass_id", ClassData.default_subclass(sprite_id))
		if u.has_method("apply_base_inhesion"):
			u.apply_base_inhesion()
	return u


## Unlock subclass inhesion on all player units up to the tier for `grade`
## (grade 2 -> 고유1, 3 -> 고유2, 4 -> 고유3).
func apply_inhesion_for_grade(grade: int) -> void:
	var tier: int = clampi(grade - 1, 0, 3)
	for u in units_of(TEAM_PLAYER):
		if u.has_method("unlock_inhesion"):
			u.unlock_inhesion(tier)


## Living units of a team.
func units_of(team: int) -> Array:
	var out: Array = []
	for u in units.get_children():
		if is_instance_valid(u) and u.is_in_group("unit") and int(u.get("team")) == team and int(u.get("hp")) > 0:
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


## Get the current phase.
func current_phase() -> int:
	return phase


## Enter preparation phase: deactivate units, reset latch, emit signal.
func begin_prep() -> void:
	phase = PHASE_PREP
	_resolved = false
	for u in units.get_children():
		if is_instance_valid(u) and u.has_method("set_active"):
			u.set_active(false)
	phase_changed.emit(PHASE_PREP)


## Enter combat phase: activate units, reset latch, emit signal.
func start_combat() -> void:
	phase = PHASE_COMBAT
	_resolved = false
	for u in units.get_children():
		if is_instance_valid(u) and u.has_method("set_active"):
			u.set_active(true)
	phase_changed.emit(PHASE_COMBAT)