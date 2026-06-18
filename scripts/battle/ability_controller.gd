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

func _ready() -> void:
	unit_owner = get_parent()

func configure() -> void:
	var meta: Dictionary = ClassData.subclass_ability(unit_owner.sprite_id, unit_owner.subclass_id)
	ability_id = String(meta.get("id", ""))
	skill_type = String(meta.get("type", ""))
	if skill_type == "special":
		charge_req = int(meta.get("charge_req", 3))
	elif skill_type == "general":
		cooldown = float(meta.get("cd", 8.0))
		_cd_timer = cooldown

func on_combat_start() -> void:
	if skill_type == "special":
		gain_charge(1)

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

func has_ability() -> bool:
	return ability_id != ""