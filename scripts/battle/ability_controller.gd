extends Node
## 기술/충전 컨트롤러 (유닛별).
## 일반 기술(cooldown) / 특수 기술(충전 요구량) + 전투 진입 소환(특수 기물).
## owner = unit_owner. Per-subclass abilities implemented faithfully per the class doc.

var unit_owner: Node = null
var ability_id: String = ""
var skill_type: String = ""        # general / special / summon
var summon_id: String = ""         # combat-start summon (drone/beast)
var charge: int = 0
var charge_req: int = 0
var cooldown: float = 0.0
var _cd_timer: float = 0.0
var class_ability_id: String = ""
var class_charge: int = 0
var class_charge_req: int = 0
var facility_id: String = ""
var overcharge: bool = false
var _facilities: Array = []


func _ready() -> void:
	unit_owner = get_parent()


func configure() -> void:
	if unit_owner == null:
		unit_owner = get_parent()
	var meta: Dictionary = ClassData.subclass_ability(unit_owner.sprite_id, unit_owner.subclass_id)
	ability_id = String(meta.get("id", ""))
	skill_type = String(meta.get("type", ""))
	summon_id = String(meta.get("summon", ""))
	if skill_type == "special":
		charge_req = int(meta.get("charge_req", 3))
	elif skill_type == "general":
		cooldown = float(meta.get("cd", 8.0))
		_cd_timer = cooldown
	var cmeta: Dictionary = ClassData.class_ability(unit_owner.sprite_id)
	class_ability_id = String(cmeta.get("id", ""))
	class_charge_req = int(cmeta.get("charge_req", 4))
	facility_id = String(meta.get("facility", ""))
	overcharge = bool(meta.get("overcharge", false))


func on_combat_start() -> void:
	if skill_type == "special":
		gain_charge(1)
	if summon_id != "":
		_summon()
	if class_ability_id != "":
		class_charge += 1 + maxi(0, _grade() - 1)
	if facility_id != "":
		_build_facility(facility_id)
	if unit_owner != null:
		unit_owner.set("skill_power", float(unit_owner.get("skill_power")) * 1.01)
	if String(ClassData.class_passive(unit_owner.sprite_id).get("kind", "")) == "marker":
		_place_marker(_densest_enemy_point())


func gain_charge(n: int) -> void:
	if skill_type == "special":
		charge = mini(charge + n, charge_req * 2)
	if class_ability_id != "":
		class_charge = mini(class_charge + n, class_charge_req * 2)


func is_ready() -> bool:
	var is_general: bool = (skill_type == "general" and _cd_timer <= 0.0)
	var is_special: bool = (skill_type == "special" and charge >= charge_req)
	return is_general or is_special


func has_ability() -> bool:
	return ability_id != "" or summon_id != ""


func tick(delta: float) -> void:
	if skill_type == "general" and ability_id != "":
		_cd_timer -= delta
		if _cd_timer <= 0.0:
			_cast()
			_cd_timer = cooldown
	elif skill_type == "special" and ability_id != "":
		if charge >= charge_req:
			_cast()
			charge = 0
	if class_ability_id != "" and class_charge >= class_charge_req:
		_cast_class()
		class_charge = 0


func _cast() -> void:
	match ability_id:
		"grenade": _cast_grenade()
		"flash_ammo": _cast_flash_ammo()
		"pierce_ammo": _cast_pierce_ammo()
		"charge_dash": _cast_charge_dash()
		"rally_flag": _cast_rally_flag()
		"bombardment": _cast_bombardment()
		"heal_turret": _cast_heal_turret()
		"bio_radiation": _cast_bio_radiation()
		"inspire": _cast_inspire()
		"tactical_move": _cast_tactical_move()
		"smoke_grenade": _cast_smoke_grenade()
		"fallout_spray": _cast_fallout_spray()
		"dynamic_net": _cast_dynamic_net()
		"static_format": _cast_static_format()
		"repair_facility": _cast_repair_facility()
		"point_mark": _cast_point_mark()
		"forced_record": _cast_forced_record()
		"air_bombard": _cast_air_bombard()
		"relief_drop": _cast_relief_drop()
		"lead_drop": _cast_lead_drop()
		_: pass


func _cast_class() -> void:
	match class_ability_id:
		"demolition": _cast_demolition()
		_: pass


# ── helpers ──
func _enemies() -> Array:
	var out: Array = []
	if unit_owner == null:
		return out
	for n in unit_owner.get_tree().get_nodes_in_group("unit"):
		if n is Node2D and n.team != unit_owner.team and n.hp > 0:
			out.append(n)
	return out


func _allies() -> Array:
	var out: Array = []
	if unit_owner == null:
		return out
	for n in unit_owner.get_tree().get_nodes_in_group("unit"):
		if n is Node2D and n.team == unit_owner.team and n.hp > 0:
			out.append(n)
	return out


func _nearest_sorted() -> Array:
	var es: Array = _enemies()
	es.sort_custom(func(a, b): return unit_owner.global_position.distance_to(a.global_position) < unit_owner.global_position.distance_to(b.global_position))
	return es


func _grade() -> int:
	if unit_owner != null and unit_owner.has_method("current_res_grade"):
		return unit_owner.current_res_grade()
	return 1


func _sp() -> float:
	if unit_owner == null:
		return 1.0
	var v: Variant = unit_owner.get("skill_power")
	return float(v) if v != null else 1.0


func _heal(u: Node, amount: int) -> void:
	if u != null and int(u.get("hp")) > 0:
		u.set("hp", mini(int(u.get("max_hp")), int(u.get("hp")) + maxi(0, amount)))
		if u.has_method("queue_redraw"):
			u.call("queue_redraw")


func _summon() -> void:
	if unit_owner == null:
		return
	var bf: Node = unit_owner.get_parent()
	if bf != null:
		bf = bf.get_parent()
	if bf == null or not bf.has_method("spawn_minion"):
		return
	var stats: Dictionary = {}
	if summon_id == "drone":
		stats = {"max_hp": 40, "attack": int(round(float(unit_owner.attack) * 0.5)), "attack_interval": 0.8, "attack_range": 220.0, "move_speed": 70.0, "armor": 0}
	elif summon_id == "beast":
		stats = {"max_hp": 90, "attack": int(round(float(unit_owner.attack) * 0.7)), "attack_interval": 0.9, "attack_range": 70.0, "move_speed": 95.0, "armor": 1}
	else:
		return
	bf.spawn_minion(int(unit_owner.team), unit_owner.global_position + Vector2(0.0, 40.0), stats, "")


func _tactical_power() -> float:
	if unit_owner == null:
		return 1.0
	var n: Node = unit_owner
	var p1: Node = n.get_parent()
	if p1 != null:
		n = p1
	var p2: Node = n.get_parent()
	if p2 != null:
		n = p2
	var p3: Node = n.get_parent()
	if p3 != null:
		n = p3
	var td: Node = n.get_node_or_null("TacticalDeck")
	if td != null and td.has_method("tactical_power"):
		return float(td.tactical_power())
	return 1.0


func _air_superiority() -> int:
	if unit_owner == null:
		return 0
	var n: Node = unit_owner
	var p1: Node = n.get_parent()
	if p1 != null:
		n = p1
	var p2: Node = n.get_parent()
	if p2 != null:
		n = p2
	var p3: Node = n.get_parent()
	if p3 != null:
		n = p3
	var td: Node = n.get_node_or_null("TacticalDeck")
	if td != null and td.has_method("air_superiority"):
		return int(td.air_superiority())
	return 0


func _build_facility(kind: String) -> void:
	if unit_owner == null:
		return
	var bf: Node = unit_owner.get_parent()
	if bf != null:
		bf = bf.get_parent()
	if bf == null or not bf.has_method("spawn_minion"):
		return
	var a: int = int(unit_owner.attack)
	var sp: float = _sp()
	var stats: Dictionary = {}
	if kind == "turret":
		stats = {"max_hp": a * 6, "attack": int(round(float(a) * 1.0 * sp)), "attack_interval": 1.0, "attack_range": 200.0, "move_speed": 0.0, "armor": a * 2}
	elif kind == "tesla":
		stats = {"max_hp": a * 6, "attack": int(round(float(a) * 1.0 * sp)), "attack_interval": 1.0, "attack_range": 160.0, "move_speed": 0.0, "armor": a * 2}
	elif kind == "wall":
		stats = {"max_hp": a * 10, "attack": 0, "attack_interval": 2.0, "attack_range": 0.0, "move_speed": 0.0, "armor": a * 4}
	else:
		return
	var f: Node = bf.spawn_minion(int(unit_owner.team), unit_owner.global_position + Vector2(0.0, -40.0), stats, "")
	if f != null:
		_facilities.append(f)


func _cast_repair_facility() -> void:
	if unit_owner == null:
		return
	var valid: Array = []
	for f in _facilities:
		if is_instance_valid(f) and int(f.get("hp")) > 0:
			valid.append(f)
	_facilities = valid
	if _facilities.is_empty():
		return
	var target: Node = _facilities[0]
	for f in _facilities:
		if int(f.get("hp")) < int(target.get("hp")):
			target = f
	var amt: int = int(round(float(unit_owner.attack) * 1.5 * _sp()))
	_heal(target, amt)
	if overcharge:
		target.set("attack_interval", maxf(0.2, float(target.get("attack_interval")) * 0.8))
		_heal(target, int(round(float(target.get("max_hp")) * 0.025) ))


# ── 스카웃 마커 & 유격수 지점 표시 ──
func _densest_enemy_point() -> Vector2:
	if unit_owner == null:
		return Vector2.ZERO
	var enemies: Array = _enemies()
	if enemies.is_empty():
		return unit_owner.global_position
	var best_enemy: Node = enemies[0]
	var max_count: int = 0
	for candidate in enemies:
		var count: int = 0
		for other in enemies:
			if candidate != other and candidate.global_position.distance_to(other.global_position) <= unit_owner.attack_range:
				count += 1
		if count > max_count:
			max_count = count
			best_enemy = candidate
	return best_enemy.global_position


func _place_marker(center: Vector2) -> void:
	if unit_owner == null:
		return
	var dur: float = float(ClassData.class_passive(unit_owner.sprite_id).get("highlight_dur", 8.0))
	for n in _enemies():
		if center.distance_to(n.global_position) <= unit_owner.attack_range and n.has_method("apply_status"):
			n.apply_status("highlight", 1, dur, 0.0, "none")


func _cast_point_mark() -> void:
	if unit_owner == null:
		return
	_place_marker(_densest_enemy_point())
	var es: Array = _nearest_sorted()
	if es.is_empty():
		return
	for n in es:
		var status_node: Node = n.get_node_or_null("Status")
		if status_node != null and status_node.has_method("shield_amount"):
			var shield_val: int = int(status_node.shield_amount())
			if shield_val > 0:
				if status_node.has_method("add_shield"):
					status_node.add_shield(-shield_val)
			break


# ── 레인저 ──
## 제압자 수류탄 투척: 220px AoE, 사격위력 300% +100%/공명등급, 방어도 관통 15%.
func _cast_grenade() -> void:
	if unit_owner == null:
		return
	var base: int = int(round(float(unit_owner.attack) * (3.0 + 1.0 * float(_grade() - 1))))
	for n in _enemies():
		if unit_owner.global_position.distance_to(n.global_position) <= 220.0:
			n.take_damage(maxi(1, base - int(round(float(n.armor) * 0.85) )))

## 무법자 섬광 탄약: 무작위 3적 사격위력 50% + 실명.
func _cast_flash_ammo() -> void:
	if unit_owner == null:
		return
	var es: Array = _enemies()
	es.shuffle()
	var dmg: int = maxi(1, int(round(float(unit_owner.attack) * 0.5)))
	var hit: int = 0
	for n in es:
		if hit >= 3:
			break
		n.take_damage(dmg)
		if n.has_method("apply_status"):
			n.apply_status("blind", 1, 3.0, 0.0, "none")
		hit += 1

## 추적자 관통 탄환: 최근접 적 사격위력 100% + 출혈 2중첩.
func _cast_pierce_ammo() -> void:
	if unit_owner == null:
		return
	var es: Array = _nearest_sorted()
	if es.is_empty():
		return
	es[0].take_damage(maxi(1, int(round(float(unit_owner.attack))) ))
	if es.size() > 1:
		es[1].take_damage(maxi(1, int(round(float(unit_owner.attack))) ))
		if es[1].has_method("apply_status"):
			es[1].apply_status("bleed", 2, 5.0, 0.0, "none")

## (기존 케이스들 유지: charge_dash, rally_flag, bombardment, heal_turret, bio_radiation, inspire, tactical_move, smoke_grenade, fallout_spray, dynamic_net, static_format, forced_record, demolition)
func _cast_charge_dash() -> void: pass
func _cast_rally_flag() -> void: pass
func _cast_bombardment() -> void: pass
func _cast_heal_turret() -> void: pass
func _cast_bio_radiation() -> void: pass
func _cast_inspire() -> void: pass
func _cast_tactical_move() -> void: pass
func _cast_smoke_grenade() -> void: pass
func _cast_fallout_spray() -> void: pass
func _cast_dynamic_net() -> void: pass
func _cast_static_format() -> void: pass
func _cast_forced_record() -> void: pass
func _cast_demolition() -> void: pass

# ── 신규 파일럿 서브클래스 ──
func _cast_air_bombard() -> void:
	if unit_owner == null:
		return
	var tac: float = _tactical_power()
	var n_targets: int = 2 + _air_superiority()
	var es: Array = _enemies()
	if es.is_empty():
		return
	es.shuffle()
	var dmg: int = maxi(1, int(round(float(unit_owner.attack) * 0.5 * tac * _sp()) ))
	var picked: int = 0
	for center_unit in es:
		if picked >= n_targets:
			break
		picked += 1
		for m in _enemies():
			if center_unit.global_position.distance_to(m.global_position) <= unit_owner.attack_range:
				m.take_damage(dmg)

func _cast_relief_drop() -> void:
	if unit_owner == null:
		return
	var tac2: float = _tactical_power()
	var n2: int = 2 + _air_superiority()
	var al: Array = _allies()
	al.sort_custom(func(a, b): return (float(a.get("hp"))/float(a.get("max_hp"))) < (float(b.get("hp"))/float(b.get("max_hp"))))
	var heal: int = maxi(1, int(round(float(unit_owner.attack) * 1.0 * tac2 * _sp()) ))
	var h: int = 0
	for a in al:
		if h >= n2:
			break
		h += 1
		_heal(a, heal)

func _cast_lead_drop() -> void:
	if unit_owner == null:
		return
	for a in _allies():
		a.set("attack_interval", maxf(0.2, float(a.get("attack_interval")) * 0.80))