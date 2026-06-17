extends Node
class_name ItemData
## Equipment registry — weapons (the key gear slot). Each weapon is a stat-modifier
## bundle (same schema as ClassData/cards/augments) applied to a unit at spawn.
## A weapon-selection UI can come later; for now each class has a sensible default.

const WEAPONS: Dictionary = {
	"sidearm":    {"label": "보조 권총",     "desc": "Atk +3",                 "effect": {"attack_add": 3}},
	"rifle":      {"label": "전술 소총",     "desc": "Atk +15%, Range +30",    "effect": {"attack_mult": 1.15, "attack_range_add": 30.0}},
	"smg":        {"label": "기관단총",     "desc": "Attack speed up",        "effect": {"attack_interval_mult": 0.85}},
	"hammer":     {"label": "중량 해머",     "desc": "Atk +10, slower",        "effect": {"attack_add": 10, "attack_interval_mult": 1.10}},
	"shield_gen": {"label": "방벽 발생기", "desc": "Max HP +15%, Armor +3",  "effect": {"max_hp_mult": 1.15, "armor_add": 3}},
	"focus_core": {"label": "집속 코어",     "desc": "Skill power +20%, cd -10%", "effect": {"skill_power_mult": 1.20, "skill_cd_mult": 0.90}},
}

## Sensible default weapon per class.
const DEFAULT: Dictionary = {
	"protagonist": "rifle",
	"ranger": "rifle",
	"vanguard": "hammer",
	"commander": "sidearm",
	"medic": "focus_core",
}


static func has_weapon(id: String) -> bool:
	return WEAPONS.has(id)


static func weapon_ids() -> Array:
	return WEAPONS.keys()


static func effect(id: String) -> Dictionary:
	var w: Dictionary = WEAPONS.get(id, {})
	return w.get("effect", {})


static func default_for(class_id: String) -> String:
	return String(DEFAULT.get(class_id, "sidearm"))


static func weapon_label(id: String) -> String:
	return String(WEAPONS.get(id, {}).get("label", id))
