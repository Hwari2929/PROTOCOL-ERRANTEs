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
		"heal_turret":
			_cast_heal_turret()
		"bio_radiation":
			_cast_bio_radiation()
		"inspire":
			_cast_inspire()

func _heal(u: Node, amount: int) -> void:
	if u != null and u.hp > 0:
		var owner: Node = unit_owner
		var sp_val = owner.get("skill_power")
		var sp: float = 1.0
		if sp_val != null:
			sp = float(sp_val)
		u.hp = mini(u.max_hp, u.hp + maxi(0, amount))
		if u.has_method("queue_redraw"):
			u.call("queue_redraw")

func _allies() -> Array:
	var result: Array = []
	var nodes: Array = get_tree().get_nodes_in_group("unit")
	for n in nodes:
		if n.team == unit_owner.team:
			result.append(n)
	return result

func _enemies() -> Array:
	var result: Array = []
	var nodes: Array = get_tree().get_nodes_in_group("unit")
	for n in nodes:
		if n.team != unit_owner.team:
			result.append(n)
	return result

func _grade() -> int:
	return 0

func _cast_grenade() -> void:
	pass

func _cast_flash_ammo() -> void:
	pass

func _cast_pierce_ammo() -> void:
	pass

func _cast_charge_dash() -> void:
	pass

func _cast_heal_turret() -> void:
	var owner: Node = unit_owner
	var sp_val = owner.get("skill_power")
	var sp: float = 1.0
	if sp_val != null:
		sp = float(sp_val)
	var allies: Array = _allies()
	for ally in allies:
		_heal(ally, round(float(owner.attack) * 2.0 * sp))

func _cast_bio_radiation() -> void:
	var owner: Node = unit_owner
	var sp_val = owner.get("skill_power")
	var sp: float = 1.0
	if sp_val != null:
		sp = float(sp_val)
	var dmg: int = round(float(owner.attack) * 1.0 * sp)
	var allies: Array = _allies()
	var enemies: Array = _enemies()
	for ally in allies:
		if owner.global_position.distance_to(ally.global_position) <= 150.0:
			_heal(ally, dmg)
	for enemy in enemies:
		if owner.global_position.distance_to(enemy.global_position) <= 150.0:
			if enemy.has_method("take_damage"):
				enemy.call("take_damage", dmg)
			if enemy.has_method("apply_status"):
				enemy.call("apply_status", "poison", 1, 4.0, 6.0, "chemical")

func _cast_inspire() -> void:
	var owner: Node = unit_owner
	var sp_val = owner.get("skill_power")
	var sp: float = 1.0
	if sp_val != null:
		sp = float(sp_val)
	var allies: Array = _allies()
	var target: Node = null
	var min_ratio: float = 1.1
	for ally in allies:
		if ally == owner:
			continue
		if ally.hp > 0:
			var ratio: float = float(ally.hp) / float(ally.max_hp)
			if ratio < min_ratio:
				min_ratio = ratio
				target = ally
	if target != null:
		target.attack += maxi(1, int(round(3.0 * sp)))
		_heal(target, round(float(owner.attack) * 1.5 * sp))