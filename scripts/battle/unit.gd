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
var sprite_id: String = ""

var active: bool = false

var _attack_timer: float = 0.0
var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _has_sprite: bool = false
@onready var _sprite: Sprite2D = $Sprite2D

func setup(team: int) -> void:
	self.team = team
	add_to_group("unit")

func is_active() -> bool:
	return active

## Load the class/team sprite (res://assets/sprites/<sprite_id>.png) if present;
## otherwise the _draw() placeholder circle is used.
func refresh_sprite() -> void:
	if _sprite == null or sprite_id == "":
		return
	var path: String = "res://assets/sprites/%s.png" % sprite_id
	if not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path)
	if tex == null:
		return
	_sprite.texture = tex
	_sprite.centered = true
	var h: float = float(tex.get_height())
	if h > 0.0:
		var s: float = 52.0 / h
		_sprite.scale = Vector2(s, s)
	_has_sprite = true
	queue_redraw()

func set_active(value: bool) -> void:
	active = value

func _physics_process(delta: float) -> void:
	if not active:
		return
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
	var candidates: Array[Node] = get_tree().get_nodes_in_group("unit")
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
	queue_redraw()
	_flash()
	if hp <= 0:
		die()

func _flash() -> void:
	if _sprite == null:
		return
	_sprite.modulate = Color(1.6, 0.6, 0.6, 1.0)
	var t: Tween = create_tween()
	t.tween_property(_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)

func die() -> void:
	died.emit()
	remove_from_group("unit")
	active = false
	# Fade + shrink out, then free (combat state is already correct: out of group, hp<=0).
	var t: Tween = create_tween()
	t.set_parallel(true)
	t.tween_property(self, "modulate:a", 0.0, 0.3)
	t.tween_property(self, "scale", Vector2(0.3, 0.3), 0.3)
	t.finished.connect(queue_free)

func _unhandled_input(event: InputEvent) -> void:
	if active or team != 0:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var dist: float = global_position.distance_to(event.position)
				if dist <= 28.0:
					_is_dragging = true
					_drag_offset = global_position - event.position
			else:
				_is_dragging = false
	elif _is_dragging and event is InputEventMouseMotion:
		var new_pos: Vector2 = event.position + _drag_offset
		new_pos.x = clampf(new_pos.x, 60.0, 600.0)
		new_pos.y = clampf(new_pos.y, 80.0, 640.0)
		global_position = new_pos

func _draw() -> void:
	if not _has_sprite:
		var color: Color = Color.BLUE if team == 0 else Color.RED
		draw_circle(Vector2.ZERO, 20.0, color)
	# HP bar above the unit, shown only while damaged and alive.
	if hp > 0 and hp < max_hp:
		var w: float = 40.0
		var bh: float = 5.0
		var top: Vector2 = Vector2(-w / 2.0, -40.0)
		var ratio: float = clampf(float(hp) / float(max_hp), 0.0, 1.0)
		draw_rect(Rect2(top, Vector2(w, bh)), Color(0.0, 0.0, 0.0, 0.6))
		var fill: Color = Color(0.2, 0.9, 0.3).lerp(Color(0.9, 0.2, 0.2), 1.0 - ratio)
		draw_rect(Rect2(top, Vector2(w * ratio, bh)), fill)