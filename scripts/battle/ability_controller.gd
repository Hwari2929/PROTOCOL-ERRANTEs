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


func on_combat_start() -> void:
	if skill_type == "special":
		gain_charge(1)
	if summon_id != "":
		_summon()


func gain_charge(n: int) -> void:
	if skill_type == "special":
		charge = mini(charge + n, charge_req * 2)


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


# ── 레인저 ──
## 제압자 수류탄 투척: 220px AoE, 사격위력 300% +100%/공명등급, 방어도 관통 15%.
func _cast_grenade() -> void:
	if unit_owner == null:
		return
	var base: int = int(round(float(unit_owner.attack) * (3.0 + 1.0 * float(_grade() - 1))))
	for n in _enemies():
		if unit_owner.global_position.distance_to(n.global_position) <= 220.0:
			n.take_damage(maxi(1, base - int(round(float(n.armor) * 0.85))))

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
	es[0].take_damage(maxi(1, int(round(float(unit_owner.attack)))))
	if es[0].has_method("apply_status"):
		es[0].apply_status("bleed", 2, 6.0, 5.0, "physical")


# ── 뱅가드 ──
## 돌격자 돌진: 최근접 적 돌진, 타격위력 300% + 방어도 100%, 120px 밀쳐내기, 2초 기절.
func _cast_charge_dash() -> void:
	if unit_owner == null:
		return
	var es: Array = _nearest_sorted()
	if es.is_empty():
		return
	var t: Node = es[0]
	var dir_to: Vector2 = (t.global_position - unit_owner.global_position).normalized()
	unit_owner.global_position = t.global_position - dir_to * 60.0
	t.take_damage(int(round(float(unit_owner.attack) * 3.0 + float(unit_owner.armor))))
	var away: Vector2 = (t.global_position - unit_owner.global_position).normalized()
	if away.length() > 0.0:
		t.global_position = t.global_position + away * 120.0
	if t.has_method("apply_stun"):
		t.apply_stun(2.0)

## 수호자 깃발 전개: 200px 내 아군 방어도 +4, 최대체력 10% 실드.
func _cast_rally_flag() -> void:
	if unit_owner == null:
		return
	for a in _allies():
		if unit_owner.global_position.distance_to(a.global_position) <= 200.0:
			a.set("armor", int(a.get("armor")) + 4)
			if a.has_method("add_shield"):
				a.add_shield(int(round(float(a.get("max_hp")) * 0.10)))


# ── 커맨더 ──
## 사령관 지정 포격: 최저 체력 적 기준 150px AoE 사격위력 200% + 40% 기절.
func _cast_bombardment() -> void:
	if unit_owner == null:
		return
	var es: Array = _enemies()
	if es.is_empty():
		return
	var low: Node = es[0]
	for n in es:
		if int(n.get("hp")) < int(low.get("hp")):
			low = n
	var dmg: int = int(round(float(unit_owner.attack) * 2.0))
	for n in es:
		if low.global_position.distance_to(n.global_position) <= 150.0:
			n.take_damage(dmg)
			if randf() < 0.4 and n.has_method("apply_stun"):
				n.apply_stun(2.0)


# ── 메딕 ──
## 치유사 치유 포탑: 전체 아군 회복 (기술 위력 기반).
func _cast_heal_turret() -> void:
	if unit_owner == null:
		return
	var amt: int = int(round(float(unit_owner.attack) * 2.0 * _sp()))
	for a in _allies():
		_heal(a, amt)

## 정화자 생체 방사: 150px 적 화학 피해 + 중독, 아군 회복.
func _cast_bio_radiation() -> void:
	if unit_owner == null:
		return
	var dmg: int = int(round(float(unit_owner.attack) * _sp()))
	for a in _allies():
		if unit_owner.global_position.distance_to(a.global_position) <= 150.0:
			_heal(a, dmg)
	for n in _enemies():
		if unit_owner.global_position.distance_to(n.global_position) <= 150.0:
			n.take_damage(dmg)
			if n.has_method("apply_status"):
				n.apply_status("poison", 1, 4.0, 6.0, "chemical")

## 조언자 고취(격려): 최저 체력 아군(자신 제외) 공격 강화 + 회복.
func _cast_inspire() -> void:
	if unit_owner == null:
		return
	var target: Node = null
	var min_ratio: float = 1.1
	for a in _allies():
		if a == unit_owner or int(a.get("hp")) <= 0:
			continue
		var r: float = float(a.get("hp")) / float(a.get("max_hp"))
		if r < min_ratio:
			min_ratio = r
			target = a
	if target != null:
		target.set("attack", int(target.get("attack")) + maxi(1, int(round(3.0 * _sp()))))
		_heal(target, int(round(float(unit_owner.attack) * 1.5 * _sp())))
