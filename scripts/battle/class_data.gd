extends Node
class_name ClassData
## Class / subclass / inhesion registry (data-driven).
##
## Structure (faithful to the ERRANTES design): each class has a BASE inhesion
## (applied at spawn, always on) and a set of SUBCLASSES. Each subclass has three
## inhesion tiers — 고유1 / 고유2 / 고유3 — unlocked progressively as the unit's
## resonance grade rises (grade 2 -> tier 1, 3 -> tier 2, 4 -> tier 3). 고유4 is not
## implemented yet.
##
## Effects are simplified into stat-modifier bundles for now (the doc's charge/skill
## mechanics can replace these later). A bundle is a Dictionary with any of:
##   attack_mult, attack_add, max_hp_mult, armor_add,
##   attack_interval_mult (<1 = faster), move_speed_mult, attack_range_add,
##   skill_cd_mult (<1 = faster skills)

const CLASSES: Dictionary = {
	"protagonist": {
		"label": "주인공",
		"base": {"attack_mult": 1.10, "max_hp_mult": 1.10},
		"subclasses": {
			"duelist": {"label": "결투가", "tiers": [
				{"attack_mult": 1.20},
				{"attack_add": 5, "attack_interval_mult": 0.90},
				{"attack_mult": 1.25, "skill_cd_mult": 0.85},
			]},
			"warden": {"label": "수문장", "tiers": [
				{"max_hp_mult": 1.20, "armor_add": 3},
				{"armor_add": 5},
				{"max_hp_mult": 1.20, "skill_cd_mult": 0.85},
			]},
		},
	},
	"ranger": {
		"label": "레인저",
		"base": {"attack_mult": 1.25, "attack_interval_mult": 0.95},
		"subclasses": {
			"suppressor": {"label": "제압자", "tiers": [
				{"attack_mult": 1.20, "skill_cd_mult": 0.90, "skill_power_mult": 1.25},
				{"attack_add": 6, "skill_power_mult": 1.15},
				{"attack_mult": 1.20, "attack_range_add": 40.0},
			]},
			"tracker": {"label": "추적자", "tiers": [
				{"attack_interval_mult": 0.85},
				{"attack_mult": 1.25},
				{"attack_add": 8, "skill_cd_mult": 0.85},
			]},
		},
	},
	"vanguard": {
		"label": "뱅가드",
		"base": {"max_hp_mult": 1.15, "armor_add": 3},
		"subclasses": {
			"guardian": {"label": "수호자", "tiers": [
				{"armor_add": 5, "max_hp_mult": 1.15},
				{"armor_add": 6},
				{"max_hp_mult": 1.20, "skill_cd_mult": 0.85},
			]},
			"charger": {"label": "돌격자", "tiers": [
				{"move_speed_mult": 1.25, "attack_mult": 1.15},
				{"attack_add": 5},
				{"attack_mult": 1.25, "skill_cd_mult": 0.85},
			]},
		},
	},
	"commander": {
		"label": "커맨더",
		"base": {"attack_mult": 1.10, "attack_range_add": 20.0},
		"subclasses": {
			"overseer": {"label": "감시자", "tiers": [
				{"attack_range_add": 40.0, "attack_mult": 1.15},
				{"attack_add": 5},
				{"attack_mult": 1.20, "skill_cd_mult": 0.85},
			]},
			"warlord": {"label": "사령관", "tiers": [
				{"attack_mult": 1.20},
				{"attack_interval_mult": 0.88},
				{"attack_add": 7, "skill_cd_mult": 0.85},
			]},
		},
	},
	"medic": {
		"label": "메딕",
		"base": {"max_hp_mult": 1.10, "skill_cd_mult": 0.90},
		"subclasses": {
			"healer": {"label": "치유사", "tiers": [
				{"skill_cd_mult": 0.85, "max_hp_mult": 1.10},
				{"max_hp_mult": 1.15},
				{"skill_cd_mult": 0.85, "armor_add": 3},
			]},
			"purifier": {"label": "정화자", "tiers": [
				{"attack_mult": 1.20, "skill_power_mult": 1.20},
				{"attack_add": 4, "skill_cd_mult": 0.90, "skill_power_mult": 1.20},
				{"attack_mult": 1.20, "max_hp_mult": 1.10},
			]},
		},
	},
}


static func has_class(class_id: String) -> bool:
	return CLASSES.has(class_id)


## First subclass id for a class (default selection).
static func default_subclass(class_id: String) -> String:
	var c: Dictionary = CLASSES.get(class_id, {})
	var subs: Dictionary = c.get("subclasses", {})
	for k in subs:
		return String(k)
	return ""


static func subclass_ids(class_id: String) -> Array:
	var c: Dictionary = CLASSES.get(class_id, {})
	var subs: Dictionary = c.get("subclasses", {})
	return subs.keys()


static func base_mods(class_id: String) -> Dictionary:
	var c: Dictionary = CLASSES.get(class_id, {})
	return c.get("base", {})


## Tier is 1-based (1/2/3). Returns {} if out of range.
static func tier_mods(class_id: String, subclass_id: String, tier: int) -> Dictionary:
	var c: Dictionary = CLASSES.get(class_id, {})
	var subs: Dictionary = c.get("subclasses", {})
	var sub: Dictionary = subs.get(subclass_id, {})
	var tiers: Array = sub.get("tiers", [])
	if tier >= 1 and tier <= tiers.size():
		return tiers[tier - 1]
	return {}


## Apply a stat-modifier bundle to a unit (script vars via set()/get()).
static func apply_mods(u: Node, mods: Dictionary) -> void:
	if u == null or mods.is_empty():
		return
	if mods.has("attack_mult"):
		u.set("attack", int(round(float(u.get("attack")) * float(mods["attack_mult"]))))
	if mods.has("attack_add"):
		u.set("attack", int(u.get("attack")) + int(mods["attack_add"]))
	if mods.has("max_hp_mult"):
		var old_hp: int = int(u.get("max_hp"))
		var new_hp: int = int(round(float(old_hp) * float(mods["max_hp_mult"])))
		u.set("max_hp", new_hp)
		u.set("hp", int(u.get("hp")) + (new_hp - old_hp))
	if mods.has("armor_add"):
		u.set("armor", int(u.get("armor")) + int(mods["armor_add"]))
	if mods.has("attack_interval_mult"):
		u.set("attack_interval", maxf(0.2, float(u.get("attack_interval")) * float(mods["attack_interval_mult"])))
	if mods.has("move_speed_mult"):
		u.set("move_speed", float(u.get("move_speed")) * float(mods["move_speed_mult"]))
	if mods.has("attack_range_add"):
		u.set("attack_range", float(u.get("attack_range")) + float(mods["attack_range_add"]))
	if mods.has("skill_cd_mult"):
		u.set("skill_cd", maxf(0.5, float(u.get("skill_cd")) * float(mods["skill_cd_mult"])))
	if mods.has("skill_power_mult"):
		u.set("skill_power", float(u.get("skill_power")) * float(mods["skill_power_mult"]))
