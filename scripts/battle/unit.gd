extends Node2D

signal hp_changed(current: int, max: int)
signal died()

## Per-class active-skill cooldown (seconds). Classes not listed have no skill.
const SKILL_CD: Dictionary = {
	"protagonist": 5.0,  # nova: AoE damage to nearby enemies
	"ranger": 4.0,       # volley: big hit on current target
	"vanguard": 6.0,     # fortify: +armor (self)
	"commander": 5.0,    # rally: +attack to all allies
	"medic": 3.5,        # mend: heal lowest-HP ally
}

## Floating text shown when a class casts its skill.
const SKILL_NAME: Dictionary = {
	"protagonist": "NOVA", "ranger": "VOLLEY", "vanguard": "FORTIFY",
	"commander": "RALLY", "medic": "MEND",
}

var team: int = 0
var max_hp: int = 100
var hp: int = 100
var attack: int = 10
var attack_interval: float = 1.0
var attack_range: float = 100.0
var move_speed: float = 50.0
var armor: int = 0
var sprite_id: String = ""        # also serves as the class id
var body_scale: float = 1.0
var subclass_id: String = ""
var inhesion_tier: int = 0        # 0 = base only; 1/2/3 = 고유1/2/3 unlocked
var weapon_id: String = ""        # equipped weapon (ItemData)

var active: bool = false

var skill_cd: float = 0.0
var skill_timer: float = 0.0
var skill_power: float = 1.0       # multiplier on skill magnitude (inhesion/cards scale it)

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
	skill_cd = float(SKILL_CD.get(sprite_id, 0.0))
	skill_timer = skill_cd
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
		var s: float = 52.0 / h * body_scale
		_sprite.scale = Vector2(s, s)
	_has_sprite = true
	queue_redraw()

func set_active(value: bool) -> void:
	active = value

## Apply the class BASE inhesion (always on). Call once at spawn after stats are set.
func apply_base_inhesion() -> void:
	if ClassData.has_class(sprite_id):
		ClassData.apply_mods(self, ClassData.base_mods(sprite_id))

## Apply the equipped weapon's stat bundle. Call once at spawn after base stats.
func equip_weapon() -> void:
	if ItemData.has_weapon(weapon_id):
		ClassData.apply_mods(self, ItemData.effect(weapon_id))

## Unlock the subclass inhesion up to `tier` (1=고유1 .. 3=고유3), applying any
## tiers not yet applied. Idempotent for already-unlocked tiers.
func unlock_inhesion(tier: int) -> void:
	if tier <= inhesion_tier or not ClassData.has_class(sprite_id):
		return
	var t: int = inhesion_tier + 1
	while t <= tier:
		var mods: Dictionary = ClassData.tier_mods(sprite_id, subclass_id, t)
		if not mods.is_empty():
			ClassData.apply_mods(self, mods)
		t += 1
	inhesion_tier = tier

func _physics_process(delta: float) -> void:
	if not active:
		return
	if hp <= 0:
		return

	# Active skill on its own cooldown (independent of basic attacks).
	if skill_cd > 0.0:
		skill_timer -= delta
		if skill_timer <= 0.0:
			skill_timer = skill_cd
			_use_skill()

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
	# Spawn the floating number into the BattleField (NOT the Units container, whose
	# children are scanned by units_of()).
	var host: Node = get_parent()
	if host != null and host.get_parent() is Node2D:
		host = host.get_parent()
	if host is Node2D:
		var col: Color = Color(1.0, 0.85, 0.3) if team == 1 else Color(1.0, 0.5, 0.5)
		DamageNumber.spawn(host, global_position, amount, col)
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

# ── Active skills (dispatched by class = sprite_id) ──
func _use_skill() -> void:
	match sprite_id:
		"protagonist":   # Nova — AoE burst to nearby enemies
			_skill_nova(int(round(float(attack) * 1.6 * skill_power)), 250.0)
		"ranger":        # Volley — burst on the 3 nearest enemies
			_skill_volley(int(round(float(attack) * 2.2 * skill_power)), 3)
		"vanguard":      # Fortify — gain armor + patch self up
			_skill_fortify()
		"commander":     # Rally — permanently raise allies' attack
			_skill_rally(maxi(1, int(round(3.0 * skill_power))))
		"medic":         # Mend — heal the lowest-HP ally
			_skill_mend(int(round((float(max_hp) * 0.18 + 12.0) * skill_power)))
	_skill_pulse()
	var host: Node2D = _fx_host()
	if host != null and SKILL_NAME.has(sprite_id):
		DamageNumber.spawn_text(host, global_position + Vector2(0.0, -16.0), String(SKILL_NAME[sprite_id]), Color(0.6, 1.0, 1.0))

## Returns the BattleField (or nearest Node2D ancestor) to host floating FX.
func _fx_host() -> Node2D:
	var host: Node = get_parent()
	if host != null and host.get_parent() is Node2D:
		host = host.get_parent()
	return host as Node2D

func _skill_nova(dmg: int, radius: float) -> void:
	for n in _units_on(false):
		if global_position.distance_to(n.global_position) <= radius:
			n.take_damage(dmg)

## Hit the `max_targets` nearest enemies.
func _skill_volley(dmg: int, max_targets: int) -> void:
	var enemies: Array = _units_on(false)
	enemies.sort_custom(func(a, b): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
	var hit: int = 0
	for n in enemies:
		if hit >= max_targets:
			break
		n.take_damage(dmg)
		hit += 1

## Gain armor and patch up (frontline sustain).
func _skill_fortify() -> void:
	armor += 4
	var healed: int = int(round(float(max_hp) * 0.10 * skill_power))
	hp = mini(max_hp, hp + healed)
	queue_redraw()

func _skill_rally(amount: int) -> void:
	for n in _units_on(true):
		n.attack += amount

func _skill_mend(amount: int) -> void:
	var lowest: Node2D = null
	var lowest_ratio: float = 1.0
	for n in _units_on(true):
		var r: float = float(n.hp) / float(n.max_hp)
		if n.hp < n.max_hp and r < lowest_ratio:
			lowest_ratio = r
			lowest = n
	if lowest != null:
		lowest.hp = mini(lowest.max_hp, lowest.hp + amount)
		lowest.queue_redraw()

## Living units; allies==true -> same team, allies==false -> enemy team.
func _units_on(allies: bool) -> Array:
	var out: Array = []
	for n in get_tree().get_nodes_in_group("unit"):
		if n is Node2D and n.hp > 0 and ((n.team == team) == allies):
			out.append(n)
	return out

## Brief cyan flash to signal a skill firing.
func _skill_pulse() -> void:
	if _sprite == null:
		return
	_sprite.modulate = Color(0.6, 1.2, 1.6, 1.0)
	var t: Tween = create_tween()
	t.tween_property(_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.18)

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