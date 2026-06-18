extends Node
## 기술/충전 컨트롤러 (유닛별) — SCAFFOLD STUB.
## Foundation for faithful class signatures: 일반 기술(cooldown) / 특수 기술(충전 요구량),
## 충전 획득 트리거(전투 진입·결정타), and per-subclass ability dispatch. UnitRef = get_parent().

var unit_owner: Node = null
var ability_id: String = ""
var skill_type: String = ""
var charge: int = 0
var charge_req: int = 0
var cooldown: float = 0.0
var _cd_timer: float = 0.0
var summon_id: String = ""

func _ready() -> void:
	unit_owner = get_parent()

func configure() -> void:
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
		var parent_node: Node = unit_owner.get_parent()
		if parent_node != null:
			var bf: Node = parent_node.get_parent()
			if bf != null and bf.has_method("spawn_minion"):
				var stats: Dictionary = {}
				if summon_id == "drone":
					stats = {
						"max_hp": 40,
						"attack": int(round(float(unit_owner.attack) * 0.5)),
						"attack_interval": 0.8,
						"attack_range": 220.0,
						"move_speed": 70.0,
						"armor": 0
					}
				elif summon_id == "beast":
					stats = {
						"max_hp": 90,
						"attack": int(round(float(unit_owner.attack) * 0.7)),
						"attack_interval": 0.9,
						"attack_range": 70.0,
						"move_speed": 95.0,
						"armor": 1
					}
				bf.spawn_minion(unit_owner.team, unit_owner.global_position + Vector2(0, 40), stats, "")

func gain_charge(n: int) -> void:
	if skill_type == "special":
		charge = mini(charge + n, charge_req * 2)

func is_ready() -> bool:
	var is_general: bool = (skill_type == "general" and _cd_timer <= 0.0)
	var is_special: bool = (skill_type == "special" and charge >= charge_req)
	return is_general or is_special

func tick(delta: float) -> void:
	if ability_id == "":
		return
	if skill_type == "general":
		_cd_timer -= delta
		if _cd_timer <= 0.0:
			_cast()
			_cd_timer = cooldown
	elif skill_type == "special":
		if charge >= charge_req:
			_cast()
			charge = 0

func _cast() -> void:
	match ability_id:
		"grenade":
			_cast_grenade()
		"flash_ammo":
			_cast_flash_ammo()
		"pierce_ammo":
			_cast_pierce_ammo()
		"charge_dash":
			_cast_charge_dash()
		"rally_flag":
			_cast_rally_flag()
		"bombardment":
			_cast_bombardment()
		_:
			pass

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

func _grade() -> int:
	if unit_owner != null and unit_owner.has_method("current_res_grade"):
		return unit_owner.current_res_grade()
	return 1

## 제압자 특수기술 수류탄 투척: 220px AoE, 사격위력 300% +100%/공명등급, 방어도 관통 15%.
func _cast_grenade() -> void:
	if unit_owner == null:
		return
	var base: int = int(round(float(unit_owner.attack) * (3.0 + 1.0 * float(_grade() - 1))))
	for n in _enemies():
		if unit_owner.global_position.distance_to(n.global_position) <= 220.0:
			var dmg: int = maxi(1, base - int(round(float(n.armor) * 0.85)))
			n.take_damage(dmg)

## 무법자 일반기술 섬광 탄약: 무작위 3적에게 사격위력 50% + 실명(명중 교란) 부여.
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

## 추적자 일반기술 관통 탄환: 최근접 적에게 사격위력 100% + 출혈 2중첩.
func _cast_pierce_ammo() -> void:
	if unit_owner == null:
		return
	var es: Array = _enemies()
	if es.is_empty():
		return
	es.sort_custom(func(a, b): return unit_owner.global_position.distance_to(a.global_position) < unit_owner.global_position.distance_to(b.global_position))
	var t: Node = es[0]
	t.take_damage(maxi(1, int(round(float(unit_owner.attack) * 1.0))))
	if t.has_method("apply_status"):
		t.apply_status("bleed", 2, 6.0, 5.0, "physical")

## 돌격자 특수기술 돌진: 최근접 적에게 돌진하여 타격위력 300% + 방어도 100% 피해 및 120px 후퇴, 2초 기절.
func _cast_charge_dash() -> void:
	if unit_owner == null:
		return
	var es: Array = _enemies()
	if es.is_empty():
		return
	
	var nearest: Node = es[0]
	var min_dist: float = unit_owner.global_position.distance_to(nearest.global_position)
	for n in es:
		var d: float = unit_owner.global_position.distance_to(n.global_position)
		if d < min_dist:
			min_dist = d
			nearest = n
	
	# Dash owner to within ~60px of target
	var dir_to: Vector2 = (nearest.global_position - unit_owner.global_position).normalized()
	var target_pos: Vector2 = nearest.global_position - dir_to * 60.0
	unit_owner.global_position = target_pos
	
	# Deal damage
	var dmg: int = int(round(float(unit_owner.attack) * 3.0 + float(unit_owner.armor) * 1.0))
	if nearest.has_method("take_damage"):
		nearest.take_damage(dmg)
	
	# Knock back target ~120px away from owner
	var dir_away: Vector2 = (nearest.global_position - unit_owner.global_position).normalized()
	if dir_away.length() > 0.0:
		nearest.global_position = nearest.global_position + dir_away * 120.0
	
	# Stun target
	if nearest.has_method("apply_stun"):
		nearest.apply_stun(2.0)

## 수호자 특수기술 깃발 전개: 200px 내 아군 방어력 +4, 최대 HP의 10% 실드 부여.
func _cast_rally_flag() -> void:
	if unit_owner == null:
		return
	var allies: Array = _allies()
	for ally in allies:
		if unit_owner.global_position.distance_to(ally.global_position) <= 200.0:
			ally.armor += 4
			if ally.has_method("add_shield"):
				var shield_amt: int = int(round(float(ally.max_hp) * 0.10))
				ally.add_shield(shield_amt)

## 사령관 특수 5pt 지정 포격: LOWEST-hp 적을 표적으로 150px 반경 물리 피해 + 40% 기절.
func _cast_bombardment() -> void:
	if unit_owner == null:
		return
	var enemies: Array = _enemies()
	if enemies.is_empty():
		return
	
	var target: Node = enemies[0]
	for e in enemies:
		if e.hp < target.hp:
			target = e
	
	var aoe_center: Vector2 = target.global_position
	var aoe_radius: float = 150.0
	var base_dmg: int = int(round(float(unit_owner.attack) * 2.0))
	
	for e in enemies:
		if aoe_center.distance_to(e.global_position) <= aoe_radius:
			e.take_damage(base_dmg)
			if randf() < 0.4:
				if e.has_method("apply_stun"):
					e.apply_stun(2.0)

func has_ability() -> bool:
	return ability_id != ""