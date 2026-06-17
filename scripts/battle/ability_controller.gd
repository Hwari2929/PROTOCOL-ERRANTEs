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

func _cast_grenade() -> void:
	pass

func _cast_flash_ammo() -> void:
	pass

func _cast_pierce_ammo() -> void:
	pass

func has_ability() -> bool:
	return ability_id != ""