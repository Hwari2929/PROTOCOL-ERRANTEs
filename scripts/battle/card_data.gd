extends Node
class_name CardData
## Tactical card registry. Effects reuse the ClassData stat-bundle schema
## (attack_mult/attack_add/max_hp_mult/armor_add/attack_interval_mult/
## move_speed_mult/attack_range_add/skill_cd_mult) plus a special "draw" key.
## In-engine display uses the English `desc` (default font has no Hangul); the Korean
## `label` is kept for when the font cycle lands.

const BASE: Array = [
	{"id": "focus_fire",   "label": "집중 사격",   "cost": 1, "desc": "Ranged power +15%",  "effect": {"attack_mult": 1.15}},
	{"id": "heavy_rounds", "label": "고폭탄",       "cost": 1, "desc": "Ranged power +6",    "effect": {"attack_add": 6}},
	{"id": "melee_drill",  "label": "근접 훈련",   "cost": 1, "desc": "Melee power +15%",   "effect": {"attack_mult": 1.15}},
	{"id": "brutal_strike","label": "잔혹한 일격", "cost": 2, "desc": "Melee power +8",     "effect": {"attack_add": 8}},
	{"id": "vitality",     "label": "활력",         "cost": 1, "desc": "Max HP +15%",       "effect": {"max_hp_mult": 1.15}},
	{"id": "fortress",     "label": "요새",         "cost": 2, "desc": "Max HP +25%",       "effect": {"max_hp_mult": 1.25}},
	{"id": "plating",      "label": "장갑판",       "cost": 1, "desc": "Armor +4",          "effect": {"armor_add": 4}},
	{"id": "bulwark",      "label": "방벽",         "cost": 2, "desc": "Armor +7",          "effect": {"armor_add": 7}},
	{"id": "adrenaline",   "label": "아드레날린",   "cost": 2, "desc": "Attack speed up",   "effect": {"attack_interval_mult": 0.85}},
	{"id": "swift",        "label": "신속",         "cost": 1, "desc": "Move speed +20%",   "effect": {"move_speed_mult": 1.20}},
	{"id": "longshot",     "label": "원거리 조준", "cost": 1, "desc": "Range +50",         "effect": {"attack_range_add": 50.0}},
	{"id": "overdrive",    "label": "과부하",       "cost": 3, "desc": "All power +25%",    "effect": {"attack_mult": 1.25}},
	{"id": "iron_skin",    "label": "강철 피부",   "cost": 2, "desc": "Armor +3, HP +10%", "effect": {"armor_add": 3, "max_hp_mult": 1.10}},
	{"id": "war_cry",      "label": "전투 함성",   "cost": 2, "desc": "Atk +5, Move +15%", "effect": {"attack_add": 5, "move_speed_mult": 1.15}},
	{"id": "resonant_edge","label": "공명의 칼날", "cost": 2, "desc": "Skill cooldown -15%","effect": {"skill_cd_mult": 0.85}},
]

## Added to the deck only when a Commander is on the team.
const COMMANDER: Array = [
	{"id": "rapid_tactics", "label": "급조 전술",   "cost": 1, "desc": "Draw 2 cards",        "effect": {"draw": 2}},
	{"id": "joint_effort",  "label": "공동의 노력", "cost": 2, "desc": "All power +20%",      "effect": {"attack_mult": 1.20}},
	{"id": "numbers",       "label": "수적 우위",   "cost": 2, "desc": "HP +15%, Armor +4",   "effect": {"max_hp_mult": 1.15, "armor_add": 4}},
	{"id": "high_ground",   "label": "고지 점거",   "cost": 2, "desc": "Range +30, power +10%","effect": {"attack_range_add": 30.0, "attack_mult": 1.10}},
]


## Full deck list for the run: 15 base cards (+ commander cards if a commander is fielded).
static func build(has_commander: bool) -> Array:
	var out: Array = []
	for c in BASE:
		out.append(c)
	if has_commander:
		for c in COMMANDER:
			out.append(c)
	return out
