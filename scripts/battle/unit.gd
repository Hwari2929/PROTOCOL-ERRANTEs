extends Node2D

signal hp_changed(current: int, max: int)
signal died()

var team: int = 0
var max_hp: int = 100
var hp: int = 100
var attack: int = 10
var attack_interval: float = 1.0
var attack_range: float = 100.0
var move_speed: float = 50.0
var armor: int = 0

var _attack_timer: float = 0.0

func setup(team: int) -> void:
	self.team = team
	add_to_group("unit")

func _physics_process(delta: float) -> void:
	if hp <= 0:
		return

	var target: Node2D = acquire_target()
	if target == null:
		return

	var dist: float = global_position.distance_to(target.global_position)
	if dist > attack_range:
		var dir: Vector2 = global_position.direction_to(target.global_position)
		position += dir * move_speed * delta
	else:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			var dmg: int = maxi(1, attack - target.armor)
			target.take_damage(dmg)
			_attack_timer = attack_interval

func acquire_target() -> Node2D:
	var candidates: Array = get_tree().get_nodes_in_group("unit")
	var best_target: Node2D = null
	var best_dist: float = INF
	for node in candidates:
		if node is Node2D and node.team != team and node.hp > 0:
			var d: float = global_position.distance_to(node.global_position)
			if d < best_dist:
				best_dist = d
				best_target = node
	return best_target

func take_damage(amount: int) -> void:
	hp -= amount
	hp_changed.emit(hp, max_hp)
	if hp <= 0:
		die()

func die() -> void:
	died.emit()
	remove_from_group("unit")
	queue_free()

func _draw() -> void:
	var color: Color = Color.BLUE if team == 0 else Color.RED
	draw_circle(Vector2.ZERO, 20.0, color)