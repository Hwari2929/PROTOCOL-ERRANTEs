extends Node2D

signal hp_changed(current: int, max: int)
signal died()
signal res_grade_changed(new_grade: int)

## Per-class active-skill cooldown (seconds). Classes not listed have no skill.
const SKILL_CD: Dictionary = {
	"nova": 5.0,
	"volley": 4.0,
	"fortify": 6.0,
	"rally": 5.0,
	"mend": 3.5,
}

## Floating text shown when a class casts its skill.
const SKILL_NAME: Dictionary = {
	"nova": "광역 폭발", "volley": "연사", "fortify": "요새화",
	"rally": "독려", "mend": "치유",
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

var res_grade: int = 1
var res_points: int = 0

var active: bool = false
var benched: bool = false   # left in the 대기실 during prep → sits out the fight
var is_special: bool = false   # 특수 기물/시설 — 공명도 체계 미적용 (일반 기물 한정)
var facility_kind: String = ""     # "base" = 시설 기반(업그레이드 가능), else 업그레이드된 시설 종류
var facility_owner_atk: int = 0    # 건설한 엔지니어의 공격력(시설 스탯 스케일링용)

var skill_cd: float = 0.0
var skill_timer: float = 0.0
var skill_power: float = 1.0       # multiplier on skill magnitude (inhesion/cards scale it)

var _attack_timer: float = 0.0
var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _has_sprite: bool = false
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _status: Node = get_node_or_null("Status")
var reason: float = 50.0
var _special_ramp: float = 0.0
var _ramp_accum: float = 0.0
var _decay_accum: float = 0.0
var crit_chance: float = 0.05
var crit_mult: float = 2.0
@onready var _ability: Node = get_node_or_null("Ability")

# 센티넬 고유 특성 '제압 사격' (suppression): sustained fire on the same target
# stacks attack speed; switching targets drops all stacks.
var _supp_stacks: int = 0
var _supp_target: Node = null
var _supp_accum: float = 0.0

func setup(team: int) -> void:
	self.team = team
	add_to_group("unit")

func is_active() -> bool:
	return active

## Load the class/team sprite (res://assets/sprites/<sprite_id>.png) if present;
## otherwise the _draw() placeholder circle is used.
func refresh_sprite() -> void:
	var kind: String = ClassData.skill_for(sprite_id)
	skill_cd = float(SKILL_CD.get(kind, 0.0))
	skill_timer = skill_cd
	if _sprite == null or sprite_id == "":
		return
	var path: String = "res://assets/sprites/%s.png" % ClassData.sprite_for(sprite_id)
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

## Set the subclass and retroactively apply bonuses for all tiers already unlocked.
func set_subclass(sub_id: String) -> void:
	subclass_id = sub_id
	for t in range(1, inhesion_tier + 1):
		var mods: Dictionary = ClassData.tier_mods(sprite_id, sub_id, t)
		if not mods.is_empty():
			ClassData.apply_mods(self, mods)
	configure_ability()

func has_subclass() -> bool:
	return subclass_id != ""

func configure_ability() -> void:
	if _ability != null and _ability.has_method("configure"):
		_ability.configure()

func on_combat_start() -> void:
	if _ability != null and _ability.has_method("on_combat_start"):
		_ability.on_combat_start()
	# 조종자: board the 기갑 메카 — a large durability shield at combat entry.
	var supp: Dictionary = ClassData.subclass_supp(sprite_id, subclass_id)
	if supp.get("mecha", false):
		add_shield(maxi(0, int(round(float(max_hp) * float(supp.get("mecha_shield_mult", 2.5))))))

func res_threshold_for(g: int) -> int:
	if g <= 1: return 0
	elif g == 2: return 8
	elif g == 3: return 12
	elif g == 4: return 24
	elif g == 5: return 40
	return 9999

func gain_resonance(amount: int) -> int:
	if is_special:
		return 0   # 특수 기물/시설은 공명도 체계에서 제외
	var grades_gained: int = 0
	res_points += amount
	while res_grade < 5 and res_points >= res_threshold_for(res_grade + 1):
		res_grade += 1
		grades_gained += 1
		unlock_inhesion(res_grade - 1)
		res_grade_changed.emit(res_grade)
	return grades_gained

func current_res_grade() -> int:
	return res_grade

func current_res_points() -> int:
	return res_points

# ── 센티넬 제압 사격 (suppression passive) ──
func _is_suppression() -> bool:
	return String(ClassData.class_passive(sprite_id).get("kind", "")) == "suppression"

func suppression_stacks() -> int:
	return _supp_stacks

func suppression_max() -> int:
	var p: Dictionary = ClassData.class_passive(sprite_id)
	if p.is_empty():
		return 0
	var m: int = int(p.get("base_max_stacks", 2)) + maxi(0, res_grade - 1)
	m += int(ClassData.subclass_supp(sprite_id, subclass_id).get("max_stacks_add", 0))
	return m

func _supp_speed_per_stack() -> float:
	var base: float = float(ClassData.class_passive(sprite_id).get("speed_per_stack", 0.25))
	base += float(ClassData.subclass_supp(sprite_id, subclass_id).get("speed_per_stack_add", 0.0))
	return maxf(0.0, base)

func is_stunned() -> bool:
	return _status != null and _status.has_method("has_effect") and _status.has_effect("stun")

func apply_stun(duration: float) -> void:
	if _status != null and _status.has_method("apply_status"):
		_status.apply_status("stun", 1, duration, 0.0, "none")

func _physics_process(delta: float) -> void:
	if not active:
		return
	if hp <= 0:
		return

	# Status tick
	if _status != null:
		_status.tick(delta)

	if is_stunned():
		return

	_passive_tick(delta)
	if _ability != null:
		_ability.tick(delta)

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
		# 제압 사격: accumulate stacks while firing the same target, reset on switch.
		if _is_suppression():
			if target == _supp_target:
				_supp_accum += delta
				var si: float = float(ClassData.class_passive(sprite_id).get("stack_interval", 0.75))
				while _supp_accum >= si:
					_supp_accum -= si
					_supp_stacks = mini(_supp_stacks + 1, suppression_max())
			else:
				_supp_target = target
				_supp_stacks = 0
				_supp_accum = 0.0
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			# 리프터 고유 반중력 탄약: 정신 피해 — 방어도 100% 관통(방어도 무시).
			var antigrav: bool = String(ClassData.class_passive(sprite_id).get("kind", "")) == "antigrav"
			var dmg: int = maxi(1, attack) if antigrav else maxi(1, attack - target.armor)
			var tac: String = ClassData.tactical_of(sprite_id)
			if tac == "사이오닉":
				dmg = int(round(float(dmg) * reason_output_mult()))
			elif tac == "스페셜":
				dmg = int(round(float(dmg) * (1.0 + _special_ramp)))
			var is_crit: bool = randf() < crit_chance
			if is_crit:
				dmg = int(round(float(dmg) * crit_mult))
				if _ability != null:
					_ability.gain_charge(1)
					# 템플러 고유 소리없는 자상: 타격 치명타가 검흔(swordmark)을 중첩.
					if String(ClassData.class_passive(sprite_id).get("kind", "")) == "swordmark" and target.has_method("apply_status"):
						target.apply_status("swordmark", 1, 8.0, 0.0, "none")
			target.take_damage(dmg)
			_apply_on_hit(target)
			_apply_suppression_hit(target, dmg)
			_apply_judgment_on_hit(target, dmg)
			var eff_interval: float = attack_interval
			if _is_suppression():
				eff_interval = attack_interval / (1.0 + _supp_speed_per_stack() * float(_supp_stacks))
			_attack_timer = eff_interval

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

## Apply this unit's subclass on-hit status trait to a struck target.
func _apply_on_hit(target: Node) -> void:
	if target == null or not target.has_method("apply_status"):
		return
	var subtrait: Dictionary = ClassData.subclass_trait(sprite_id, subclass_id)
	match String(subtrait.get("on_hit", "")):
		"bleed":
			target.apply_status("bleed", 1, 4.0, 5.0, "physical")
		"burn":
			target.apply_status("burn", 1, 4.0, 5.0, "physical")
		"poison":
			target.apply_status("poison", 1, 4.0, 6.0, "chemical")
		"vulnerable":
			# 잠행자 취약점: 35% 기본 확률로 받는 피해 증가 디버프 중첩.
			if randf() < 0.35:
				target.apply_status("vulnerable", 1, 6.0, 0.0, "none")

## 센티넬 subclass on-hit suppression effects (군림자 흡혈/처형, 분쇄자 관통/초과체력).
func _apply_suppression_hit(target: Node, dmg: int) -> void:
	if not _is_suppression() or _supp_stacks <= 0:
		return
	var supp: Dictionary = ClassData.subclass_supp(sprite_id, subclass_id)
	# 군림자 흡혈: heal self by a fraction of damage per stack.
	if supp.has("lifesteal_per_stack"):
		var heal: int = int(round(float(dmg) * float(supp["lifesteal_per_stack"]) * float(_supp_stacks)))
		if heal > 0:
			hp = mini(max_hp, hp + heal)
			queue_redraw()
	# 군림자 처형: bonus damage to low-hp targets, scaling per stack.
	if supp.has("execute_per_stack") and target != null and int(target.get("hp")) > 0:
		var ratio: float = float(target.get("hp")) / float(target.get("max_hp"))
		if ratio < 0.30:
			var exec: int = int(round(float(target.get("hp")) * float(supp["execute_per_stack"]) * float(_supp_stacks)))
			if exec > 0:
				target.take_damage(exec)
	# 분쇄자 초과체력 전환: convert a fraction of damage to overshield.
	if supp.has("overheal_convert"):
		add_shield(maxi(0, int(round(float(dmg) * float(supp["overheal_convert"])))))
	# 분쇄자 관통: pierce the next nearest enemies for the same damage.
	if supp.has("pierce"):
		var pierces: int = int(supp["pierce"])
		if pierces > 0:
			var others: Array = []
			for n in get_tree().get_nodes_in_group("unit"):
				if n is Node2D and n != target and n.team != team and n.hp > 0:
					others.append(n)
			others.sort_custom(func(a, b): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
			var hit: int = 0
			for n in others:
				if hit >= pierces:
					break
				n.take_damage(dmg)
				hit += 1

## 아비터 심판(judgment): on hit, record a fraction of damage into the target,
## detonating later for fixed damage (status_controller handles the detonation).
func _apply_judgment_on_hit(target: Node, dmg: int) -> void:
	var passive: Dictionary = ClassData.class_passive(sprite_id)
	if String(passive.get("kind", "")) != "judgment" or target == null:
		return
	var st: Node = target.get_node_or_null("Status")
	if st == null or not st.has_method("record_judgment"):
		return
	var rec: int = int(round(float(dmg) * float(passive.get("record_frac", 0.35))))
	var cap: int = int(round(float(attack) * float(passive.get("cap_mult", 3.0))))
	st.record_judgment(rec, cap, float(passive.get("dur", 5.0)))

## 전투 중 이 기물이 보유한 버프/디버프/상태 요약 (정보 패널용).
func buff_summary() -> Array:
	var out: Array = []
	if _status != null:
		if _status.has_method("shield_amount") and int(_status.shield_amount()) > 0:
			out.append("초과 체력 %d" % int(_status.shield_amount()))
		for pair in [["bleed", "출혈"], ["burn", "연소"], ["poison", "중독"], ["highlight", "강조 표시"], ["vulnerable", "취약"]]:
			if _status.has_method("has_effect") and _status.has_effect(pair[0]):
				var st: int = int(_status.stacks_of(pair[0])) if _status.has_method("stacks_of") else 0
				out.append("%s%s" % [pair[1], (" %d중첩" % st) if st > 1 else ""])
		if _status.has_method("judgment_record") and int(_status.judgment_record()) > 0:
			out.append("심판 기록 %d" % int(_status.judgment_record()))
	if is_stunned():
		out.append("기절")
	if _is_suppression() and _supp_stacks > 0:
		out.append("제압 사격 %d중첩" % _supp_stacks)
	if ClassData.tactical_of(sprite_id) == "스페셜" and _special_ramp > 0.0:
		out.append("가속 +%d%%" % int(round(_special_ramp * 100.0)))
	if ClassData.tactical_of(sprite_id) == "사이오닉":
		out.append("이성 %d" % int(round(reason)))
	return out


func reason_output_mult() -> float:
	return 1.0 + clampf((50.0 - reason) / 50.0, 0.0, 1.0) * 0.5

func reason_taken_mult() -> float:
	return 1.0 + clampf((50.0 - reason) / 50.0, 0.0, 1.0) * 0.5

func _passive_tick(delta: float) -> void:
	var tac: String = ClassData.tactical_of(sprite_id)
	if tac == "스페셜":
		_ramp_accum += delta
		while _ramp_accum >= 2.0:
			_ramp_accum -= 2.0
			_special_ramp = minf(0.30, _special_ramp + 0.03)
	elif tac == "사이오닉" and reason < 0.0:
		_decay_accum += delta
		while _decay_accum >= 1.0:
			_decay_accum -= 1.0
			take_damage(maxi(1, int(round(float(max_hp) * 0.01))))

func take_damage(amount: int) -> void:
	if ClassData.tactical_of(sprite_id) == "사이오닉":
		amount = int(round(float(amount) * reason_taken_mult()))
	# 강조 표시(highlight)/취약(vulnerable) 등 받는 피해 증가 디버프.
	if _status != null and _status.has_method("damage_taken_mult"):
		amount = int(round(float(amount) * _status.damage_taken_mult()))
	if _status != null and _status.has_method("absorb"):
		amount = _status.absorb(amount)
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

func apply_status(id: String, stacks: int, duration: float, per_sec: float, dtype: String) -> void:
	if _status != null and _status.has_method("apply_status"):
		_status.apply_status(id, stacks, duration, per_sec, dtype)

func add_shield(amount: int) -> void:
	if _status != null and _status.has_method("add_shield"):
		_status.add_shield(amount)

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
	var kind: String = ClassData.skill_for(sprite_id)
	match kind:
		"nova":   # Nova — AoE burst to nearby enemies
			_skill_nova(int(round(float(attack) * 1.6 * skill_power)), 250.0)
		"volley":        # Volley — burst on the 3 nearest enemies
			_skill_volley(int(round(float(attack) * 2.2 * skill_power)), 3)
		"fortify":      # Fortify — gain armor + patch self up
			_skill_fortify()
		"rally":     # Rally — permanently raise allies' attack
			_skill_rally(maxi(1, int(round(3.0 * skill_power))))
		"mend":         # Mend — heal the lowest-HP ally
			_skill_mend(int(round((float(max_hp) * 0.18 + 12.0) * skill_power)))
	var subtrait: Dictionary = ClassData.subclass_trait(sprite_id, subclass_id)
	if String(subtrait.get("on_skill", "")) == "shield":
		add_shield(int(round(float(max_hp) * 0.15 * skill_power)))
	if ClassData.tactical_of(sprite_id) == "사이오닉":
		reason = maxf(-100.0, reason - 12.0)
	_skill_pulse()
	var host: Node2D = _fx_host()
	if host != null and SKILL_NAME.has(kind):
		DamageNumber.spawn_text(host, global_position + Vector2(0.0, -16.0), String(SKILL_NAME.get(kind, "SKILL")), Color(0.62, 0.23, 0.18))

## Returns the BattleField (or nearest Node2D ancestor) to host floating FX.
func _fx_host() -> Node2D:
	var host: Node = get_parent()
	if host != null and host.get_parent() is Node2D:
		host = host.get_parent()
	return host as Node2D

## 기술 시전 시 한글 기술명을 띄운다 (ability_controller가 호출).
func show_skill_text(txt: String) -> void:
	if txt == "":
		return
	var host: Node2D = _fx_host()
	if host != null:
		DamageNumber.spawn_text(host, global_position + Vector2(0.0, -16.0), txt, Color(0.62, 0.23, 0.18))
	_skill_pulse()

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

# Prep-phase drag/selection is owned centrally by PrepController (scripts/ui/prep_controller.gd).

func _draw() -> void:
	if not _has_sprite:
		var color: Color = Color.BLUE if team == 0 else Color.RED
		draw_circle(Vector2.ZERO, 20.0, color)
	# HP bar above the unit, shown only while damaged and alive.
	if hp > 0 and hp < max_hp:
		var w: float = 40.0
		var h: float = 4.0
		var ratio: float = float(hp) / float(max_hp)
		draw_rect(Rect2(-w / 2.0, -30.0, w * ratio, h), Color(0.2, 0.8, 0.2, 0.8))
		draw_rect(Rect2(-w / 2.0, -30.0, w, h), Color(0.0, 0.0, 0.0, 0.5))