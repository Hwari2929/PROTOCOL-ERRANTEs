extends Node
class_name ClassData
## Class / subclass / inhesion registry — the 16-class system (4 positions × 4 tactical
## types) + the protagonist. Faithful to the design doc's structure; effects are
## stat-modifier bundles for now (deeper mechanics — status effects, psionic 이성,
## special mini-systems, minor cards — layer on in later phases).
##
## Each class: label, position(명사수/돌격가/통솔자/전문가), tactical(메이저/스페셜/마이너/사이오닉),
## stats(spawn base), base(고유 특성 always-on bundle), subclasses{ id: {label, tiers[3]} }.
##
## Effect bundle keys (see apply_mods): attack_mult, attack_add, max_hp_mult, armor_add,
## attack_interval_mult(<1 faster), move_speed_mult, attack_range_add,
## skill_cd_mult(<1 faster), skill_power_mult.

## Position -> placeholder sprite id (real per-class art comes later).
const POSITION_SPRITE: Dictionary = {
	"명사수": "ranger", "돌격가": "vanguard", "통솔자": "commander", "전문가": "medic",
}
## Position -> signature skill kind (unit._use_skill dispatches on this).
const POSITION_SKILL: Dictionary = {
	"명사수": "volley", "돌격가": "fortify", "통솔자": "rally", "전문가": "mend",
}

const CLASSES: Dictionary = {
	# ── Protagonist (hero, always available) ──
	"protagonist": {
		"label": "주인공", "position": "돌격가", "tactical": "메이저", "skill": "nova", "sprite": "protagonist",
		"stats": {"max_hp": 150, "attack": 14, "attack_interval": 0.9, "attack_range": 120.0, "move_speed": 70.0, "armor": 5},
		"base": {"attack_mult": 1.10, "max_hp_mult": 1.10},
		"subclasses": {
			"duelist": {"label": "결투가", "tiers": [{"attack_mult": 1.20}, {"attack_add": 5, "attack_interval_mult": 0.90}, {"attack_mult": 1.25, "skill_power_mult": 1.20}]},
			"warden": {"label": "수문장", "tiers": [{"max_hp_mult": 1.20, "armor_add": 3}, {"armor_add": 5}, {"max_hp_mult": 1.20, "skill_cd_mult": 0.85}]},
		},
	},

	# ── 메이저 ──
	"ranger": {
		"label": "레인저", "position": "명사수", "tactical": "메이저",
		"stats": {"max_hp": 90, "attack": 20, "attack_interval": 0.7, "attack_range": 260.0, "move_speed": 60.0, "armor": 1},
		"base": {"attack_mult": 1.25, "attack_interval_mult": 0.95},
		"subclasses": {
			"suppressor": {"label": "제압자", "ability": {"id": "grenade", "type": "special", "charge_req": 3}, "tiers": [{"attack_mult": 1.20, "skill_power_mult": 1.25}, {"attack_add": 6, "skill_power_mult": 1.15}, {"attack_mult": 1.20, "attack_range_add": 40.0}]},
			"outlaw": {"label": "무법자", "ability": {"id": "flash_ammo", "type": "general", "cd": 10.0}, "tiers": [{"move_speed_mult": 1.20, "attack_interval_mult": 0.92}, {"attack_add": 5, "move_speed_mult": 1.10}, {"attack_mult": 1.20, "attack_interval_mult": 0.88}]},
			"tracker": {"label": "추적자", "trait": {"on_hit": "bleed"}, "ability": {"id": "pierce_ammo", "type": "general", "cd": 8.0}, "tiers": [{"attack_interval_mult": 0.85}, {"attack_mult": 1.25}, {"attack_add": 8, "skill_cd_mult": 0.85}]},
		},
	},
	"vanguard": {
		"label": "뱅가드", "position": "돌격가", "tactical": "메이저",
		"stats": {"max_hp": 190, "attack": 11, "attack_interval": 1.0, "attack_range": 70.0, "move_speed": 85.0, "armor": 9},
		"base": {"max_hp_mult": 1.15, "armor_add": 3},
		"subclasses": {
			"guardian": {"label": "수호자", "ability": {"id": "rally_flag", "type": "special", "charge_req": 4}, "tiers": [{"armor_add": 5, "max_hp_mult": 1.15}, {"armor_add": 6}, {"max_hp_mult": 1.20, "skill_cd_mult": 0.85}]},
			"charger": {"label": "돌격자", "trait": {"on_skill": "shield"}, "ability": {"id": "charge_dash", "type": "special", "charge_req": 3}, "tiers": [{"move_speed_mult": 1.25, "attack_mult": 1.15}, {"attack_add": 5}, {"attack_mult": 1.25, "skill_cd_mult": 0.85}]},
			"escort": {"label": "엄호자", "tiers": [{"max_hp_mult": 1.15, "armor_add": 4}, {"max_hp_mult": 1.15}, {"armor_add": 6, "skill_cd_mult": 0.85}]},
		},
	},
	"commander": {
		"label": "커맨더", "position": "통솔자", "tactical": "메이저",
		"stats": {"max_hp": 110, "attack": 12, "attack_interval": 0.9, "attack_range": 190.0, "move_speed": 65.0, "armor": 3},
		"base": {"attack_mult": 1.10, "attack_range_add": 20.0},
		"subclasses": {
			"overseer": {"label": "감시자", "ability": {"id": "watch_drone", "type": "summon", "summon": "drone"}, "tiers": [{"attack_range_add": 40.0, "attack_mult": 1.15}, {"attack_add": 5}, {"attack_mult": 1.20, "skill_cd_mult": 0.85}]},
			"warlord": {"label": "사령관", "ability": {"id": "bombardment", "type": "special", "charge_req": 5}, "tiers": [{"attack_mult": 1.20}, {"attack_interval_mult": 0.88}, {"attack_add": 7, "skill_cd_mult": 0.85}]},
			"beastmaster": {"label": "조련사", "ability": {"id": "beast_call", "type": "summon", "summon": "beast"}, "tiers": [{"skill_power_mult": 1.25, "attack_mult": 1.10}, {"attack_add": 5, "skill_power_mult": 1.15}, {"skill_power_mult": 1.20, "attack_range_add": 30.0}]},
		},
	},
	"medic": {
		"label": "메딕", "position": "전문가", "tactical": "메이저",
		"stats": {"max_hp": 100, "attack": 8, "attack_interval": 1.1, "attack_range": 160.0, "move_speed": 65.0, "armor": 2},
		"base": {"max_hp_mult": 1.10, "skill_cd_mult": 0.90},
		"subclasses": {
			"healer": {"label": "치유사", "ability": {"id": "heal_turret", "type": "special", "charge_req": 4}, "tiers": [{"skill_cd_mult": 0.85, "max_hp_mult": 1.10}, {"max_hp_mult": 1.15}, {"skill_cd_mult": 0.85, "armor_add": 3}]},
			"purifier": {"label": "정화자", "ability": {"id": "bio_radiation", "type": "special", "charge_req": 5}, "tiers": [{"attack_mult": 1.20, "skill_power_mult": 1.20}, {"attack_add": 4, "skill_cd_mult": 0.90, "skill_power_mult": 1.20}, {"attack_mult": 1.20, "max_hp_mult": 1.10}]},
			"counselor": {"label": "조언자", "ability": {"id": "inspire", "type": "general", "cd": 8.0}, "tiers": [{"skill_power_mult": 1.20, "max_hp_mult": 1.10}, {"skill_cd_mult": 0.85}, {"skill_power_mult": 1.20, "max_hp_mult": 1.10}]},
		},
	},

	# ── 스페셜 ──
	"sentinel": {
		"label": "센티넬", "position": "명사수", "tactical": "스페셜",
		"stats": {"max_hp": 150, "attack": 14, "attack_interval": 0.6, "attack_range": 170.0, "move_speed": 50.0, "armor": 4},
		"base": {"max_hp_mult": 1.20, "attack_interval_mult": 0.90},
		"passive": {"kind": "suppression", "stack_interval": 0.75, "speed_per_stack": 0.25, "base_max_stacks": 2},
		"subclasses": {
			"overlord": {"label": "군림자", "supp": {"max_stacks_add": 3, "speed_per_stack_add": -0.10, "lifesteal_per_stack": 0.01, "execute_per_stack": 0.01}, "tiers": [{"attack_mult": 1.20}, {"attack_add": 6}, {"attack_mult": 1.20, "attack_interval_mult": 0.90}]},
			"pilot_mech": {"label": "조종자", "supp": {"mecha": true, "hp_penalty": 0.40, "mecha_shield_mult": 2.5, "dmg_reduction_per_stack": 0.05, "dmg_per_stack": 0.15, "speed_per_stack_add": -0.15, "aoe": true}, "tiers": [{"max_hp_mult": 1.25, "armor_add": 5}, {"armor_add": 6}, {"max_hp_mult": 1.20, "attack_add": 6}]},
			"crusher": {"label": "분쇄자", "supp": {"pierce": 1, "overheal_convert": 0.10}, "tiers": [{"attack_add": 8, "attack_range_add": 30.0}, {"attack_mult": 1.20}, {"max_hp_mult": 1.15, "attack_add": 6}]},
		},
	},
	"breacher": {
		"label": "브리처", "position": "돌격가", "tactical": "스페셜",
		"stats": {"max_hp": 160, "attack": 13, "attack_interval": 0.95, "attack_range": 90.0, "move_speed": 90.0, "armor": 5},
		"base": {"move_speed_mult": 1.10, "skill_power_mult": 1.15},
		"class_ability": {"id": "demolition", "type": "special", "charge_req": 4},
		"subclasses": {
			"breakthrough": {"label": "돌파자", "ability": {"id": "tactical_move", "type": "general", "cd": 6.0}, "tiers": [{"move_speed_mult": 1.20, "attack_mult": 1.15}, {"attack_add": 6}, {"attack_mult": 1.20, "skill_cd_mult": 0.85}]},
			"skirmisher": {"label": "척후대", "ability": {"id": "smoke_grenade", "type": "general", "cd": 10.0}, "tiers": [{"attack_interval_mult": 0.88, "move_speed_mult": 1.10}, {"attack_add": 5}, {"attack_interval_mult": 0.85}]},
			"irradiator": {"label": "피폭자", "ability": {"id": "fallout_spray", "type": "general", "cd": 5.0}, "trait": {"on_hit": "poison"}, "tiers": [{"skill_power_mult": 1.25}, {"attack_mult": 1.15, "skill_power_mult": 1.15}, {"skill_power_mult": 1.20, "attack_add": 5}]},
		},
	},
	"cipher": {
		"label": "사이퍼", "position": "통솔자", "tactical": "스페셜",
		"stats": {"max_hp": 105, "attack": 11, "attack_interval": 0.9, "attack_range": 185.0, "move_speed": 62.0, "armor": 3},
		"base": {"skill_power_mult": 1.15, "attack_range_add": 20.0},
		"subclasses": {
			"relay": {"label": "중계자", "ability": {"id": "dynamic_net", "type": "general", "cd": 6.0}, "tiers": [{"max_hp_mult": 1.15, "skill_power_mult": 1.15}, {"max_hp_mult": 1.10}, {"skill_power_mult": 1.20, "armor_add": 3}]},
			"analyst": {"label": "분석자", "ability": {"id": "static_format", "type": "special", "charge_req": 3}, "tiers": [{"attack_mult": 1.20}, {"attack_add": 5}, {"attack_mult": 1.20, "skill_cd_mult": 0.85}]},
			"planner": {"label": "기획자", "tiers": [{"skill_cd_mult": 0.85}, {"skill_power_mult": 1.20}, {"skill_cd_mult": 0.85, "attack_add": 4}]},
		},
	},
	"engineer": {
		"label": "엔지니어", "position": "전문가", "tactical": "스페셜",
		"stats": {"max_hp": 115, "attack": 9, "attack_interval": 1.1, "attack_range": 150.0, "move_speed": 58.0, "armor": 5},
		"base": {"max_hp_mult": 1.15, "armor_add": 3},
		"subclasses": {
			"supervisor": {"label": "감독관", "ability": {"id": "repair_facility", "type": "general", "cd": 8.0, "facility": "turret"}, "tiers": [{"attack_add": 6, "attack_range_add": 40.0}, {"attack_mult": 1.15}, {"skill_power_mult": 1.20}]},
			"fortifier": {"label": "축성가", "ability": {"id": "repair_facility", "type": "general", "cd": 8.0, "facility": "wall"}, "tiers": [{"armor_add": 6, "max_hp_mult": 1.15}, {"armor_add": 6}, {"max_hp_mult": 1.20}]},
			"technician": {"label": "기술사", "ability": {"id": "repair_facility", "type": "general", "cd": 8.0, "facility": "tesla", "overcharge": true}, "tiers": [{"skill_cd_mult": 0.85, "attack_add": 4}, {"attack_interval_mult": 0.88}, {"skill_power_mult": 1.20}]},
		},
	},

	# ── 마이너 ──
	"scout": {
		"label": "스카웃", "position": "명사수", "tactical": "마이너",
		"stats": {"max_hp": 95, "attack": 17, "attack_interval": 0.8, "attack_range": 250.0, "move_speed": 68.0, "armor": 2},
		"base": {"attack_mult": 1.15, "attack_range_add": 30.0},
		"passive": {"kind": "marker", "highlight_dur": 8.0},
		"subclasses": {
			"ranger_skirm": {"label": "유격수", "ability": {"id": "point_mark", "type": "special", "charge_req": 3}, "tiers": [{"attack_range_add": 50.0}, {"attack_mult": 1.20}, {"attack_add": 6, "move_speed_mult": 1.10}]},
			"recon": {"label": "수색대", "tiers": [{"attack_mult": 1.20}, {"attack_add": 5}, {"attack_mult": 1.20, "attack_range_add": 30.0}]},
			"sentry": {"label": "파수꾼", "tiers": [{"attack_interval_mult": 0.85}, {"attack_add": 5}, {"attack_interval_mult": 0.85, "attack_mult": 1.15}]},
		},
	},
	"arbiter": {
		"label": "아비터", "position": "돌격가", "tactical": "마이너",
		"stats": {"max_hp": 175, "attack": 13, "attack_interval": 0.95, "attack_range": 80.0, "move_speed": 80.0, "armor": 7},
		"base": {"attack_mult": 1.10, "max_hp_mult": 1.10},
		"passive": {"kind": "judgment", "record_frac": 0.35, "cap_mult": 3.0, "dur": 5.0},
		"subclasses": {
			"punisher": {"label": "징벌자", "tiers": [{"armor_add": 5, "max_hp_mult": 1.15}, {"armor_add": 5}, {"attack_mult": 1.20, "armor_add": 4}]},
			"judge": {"label": "심판자", "tiers": [{"attack_mult": 1.20}, {"attack_add": 6}, {"attack_mult": 1.25, "skill_power_mult": 1.15}]},
			"recorder": {"label": "기록자", "ability": {"id": "forced_record", "type": "general", "cd": 8.0}, "tiers": [{"skill_power_mult": 1.20}, {"attack_add": 5, "skill_power_mult": 1.15}, {"skill_power_mult": 1.20}]},
		},
	},
	"pilot": {
		"label": "파일럿", "position": "통솔자", "tactical": "마이너",
		"stats": {"max_hp": 105, "attack": 12, "attack_interval": 0.9, "attack_range": 195.0, "move_speed": 66.0, "armor": 3},
		"base": {"attack_range_add": 30.0, "skill_power_mult": 1.10},
		"subclasses": {
			"controller": {"label": "통제관", "ability": {"id": "air_bombard", "type": "general", "cd": 10.0}, "tiers": [{"skill_power_mult": 1.25, "attack_range_add": 30.0}, {"skill_power_mult": 1.15}, {"attack_mult": 1.15, "skill_power_mult": 1.15}]},
			"quartermaster": {"label": "보급관", "ability": {"id": "relief_drop", "type": "general", "cd": 8.0}, "tiers": [{"skill_cd_mult": 0.85, "max_hp_mult": 1.10}, {"skill_cd_mult": 0.88}, {"skill_power_mult": 1.20}]},
			"squad_lead": {"label": "지휘관", "ability": {"id": "lead_drop", "type": "general", "cd": 12.0}, "tiers": [{"attack_add": 5, "max_hp_mult": 1.10}, {"attack_mult": 1.15}, {"attack_add": 6, "armor_add": 3}]},
		},
	},
	"ghost": {
		"label": "고스트", "position": "전문가", "tactical": "마이너",
		"stats": {"max_hp": 100, "attack": 12, "attack_interval": 1.0, "attack_range": 150.0, "move_speed": 72.0, "armor": 2},
		"base": {"skill_power_mult": 1.20, "move_speed_mult": 1.10},
		"subclasses": {
			"assassin": {"label": "암살자", "ability": {"id": "assault", "type": "special", "charge_req": 2}, "tiers": [{"attack_mult": 1.25, "skill_power_mult": 1.15}, {"attack_add": 6}, {"attack_mult": 1.25}]},
			"infiltrator": {"label": "잠행자", "ability": {"id": "sec_breach", "type": "special", "charge_req": 3}, "trait": {"on_hit": "vulnerable"}, "tiers": [{"skill_power_mult": 1.25}, {"skill_cd_mult": 0.88}, {"skill_power_mult": 1.20, "attack_add": 4}]},
			"synchronizer": {"label": "동조자", "ability": {"id": "smoke_veil", "type": "special", "charge_req": 3}, "tiers": [{"max_hp_mult": 1.15, "skill_power_mult": 1.15}, {"skill_cd_mult": 0.88}, {"skill_power_mult": 1.20, "max_hp_mult": 1.10}]},
		},
	},

	# ── 사이오닉 ──
	"lifter": {
		"label": "리프터", "position": "명사수", "tactical": "사이오닉",
		"stats": {"max_hp": 100, "attack": 16, "attack_interval": 0.85, "attack_range": 240.0, "move_speed": 60.0, "armor": 2},
		"base": {"skill_power_mult": 1.15, "attack_range_add": 20.0},
		"class_ability": {"id": "gravity_release", "type": "general", "cd": 6.0},
		"passive": {"kind": "antigrav"},
		"subclasses": {
			"tractor": {"label": "견인자", "ability": {"id": "field_collapse", "type": "special", "charge_req": 4}, "tiers": [{"skill_power_mult": 1.25}, {"attack_add": 5, "skill_power_mult": 1.10}, {"skill_power_mult": 1.20}]},
			"conveyor": {"label": "전달자", "ability": {"facility": "turret"}, "tiers": [{"move_speed_mult": 1.20, "skill_power_mult": 1.10}, {"attack_mult": 1.15}, {"skill_cd_mult": 0.85}]},
			"weaver": {"label": "방직자", "ability": {"facility": "wall"}, "tiers": [{"armor_add": 4, "max_hp_mult": 1.15}, {"max_hp_mult": 1.10}, {"armor_add": 5, "skill_power_mult": 1.15}]},
		},
	},
	"templar": {
		"label": "템플러", "position": "돌격가", "tactical": "사이오닉",
		"stats": {"max_hp": 170, "attack": 14, "attack_interval": 0.9, "attack_range": 80.0, "move_speed": 82.0, "armor": 6},
		"base": {"attack_mult": 1.15, "attack_interval_mult": 0.95},
		"subclasses": {
			"wanderer": {"label": "방랑자", "tiers": [{"move_speed_mult": 1.20, "attack_mult": 1.15}, {"attack_add": 6}, {"attack_interval_mult": 0.88}]},
			"reaper": {"label": "수확자", "trait": {"on_hit": "bleed"}, "tiers": [{"attack_mult": 1.20}, {"attack_add": 6}, {"attack_mult": 1.25, "skill_power_mult": 1.15}]},
			"resistor": {"label": "저항자", "tiers": [{"armor_add": 5, "max_hp_mult": 1.15}, {"armor_add": 5}, {"attack_mult": 1.15, "armor_add": 4}]},
		},
	},
	"oracle": {
		"label": "오라클", "position": "통솔자", "tactical": "사이오닉",
		"stats": {"max_hp": 105, "attack": 11, "attack_interval": 0.95, "attack_range": 185.0, "move_speed": 62.0, "armor": 3},
		"base": {"skill_power_mult": 1.15, "skill_cd_mult": 0.92},
		"subclasses": {
			"diviner": {"label": "점술사", "tiers": [{"skill_cd_mult": 0.85}, {"skill_power_mult": 1.20}, {"skill_cd_mult": 0.85, "skill_power_mult": 1.10}]},
			"illusionist": {"label": "환술사", "tiers": [{"skill_power_mult": 1.25}, {"skill_power_mult": 1.15}, {"attack_mult": 1.15, "skill_power_mult": 1.15}]},
			"medium": {"label": "영매사", "tiers": [{"attack_mult": 1.15, "skill_power_mult": 1.10}, {"attack_add": 5}, {"skill_power_mult": 1.20}]},
		},
	},
	"mystic": {
		"label": "미스틱", "position": "전문가", "tactical": "사이오닉",
		"stats": {"max_hp": 100, "attack": 10, "attack_interval": 1.05, "attack_range": 175.0, "move_speed": 62.0, "armor": 2},
		"base": {"skill_power_mult": 1.25, "skill_cd_mult": 0.92},
		"subclasses": {
			"liberator": {"label": "해방자", "tiers": [{"skill_power_mult": 1.25}, {"skill_cd_mult": 0.88}, {"skill_power_mult": 1.20}]},
			"pyro": {"label": "방화자", "trait": {"on_hit": "burn"}, "tiers": [{"attack_mult": 1.15, "skill_power_mult": 1.15}, {"skill_power_mult": 1.15}, {"skill_power_mult": 1.20, "attack_add": 4}]},
			"decomposer": {"label": "분해자", "tiers": [{"attack_mult": 1.20}, {"skill_power_mult": 1.15}, {"attack_mult": 1.20, "skill_power_mult": 1.10}]},
		},
	},
}


static func has_class(class_id: String) -> bool:
	return CLASSES.has(class_id)


static func class_ids() -> Array:
	return CLASSES.keys()


static func class_label(class_id: String) -> String:
	return String(CLASSES.get(class_id, {}).get("label", class_id))


static func position_of(class_id: String) -> String:
	return String(CLASSES.get(class_id, {}).get("position", ""))


static func tactical_of(class_id: String) -> String:
	return String(CLASSES.get(class_id, {}).get("tactical", ""))


static func stats_for(class_id: String) -> Dictionary:
	return CLASSES.get(class_id, {}).get("stats", {})


## Visual sprite id for a class (explicit "sprite", else position default).
static func sprite_for(class_id: String) -> String:
	var c: Dictionary = CLASSES.get(class_id, {})
	if c.is_empty():
		return class_id  # non-class (e.g. enemy "swarm") uses its own id as the sprite
	if c.has("sprite"):
		return String(c["sprite"])
	if ResourceLoader.exists("res://assets/sprites/%s.png" % class_id):
		return class_id  # class has its own sprite asset
	return String(POSITION_SPRITE.get(String(c.get("position", "")), class_id))


## Signature skill kind for a class (explicit "skill", else position default; "" if none).
static func skill_for(class_id: String) -> String:
	var c: Dictionary = CLASSES.get(class_id, {})
	if c.is_empty():
		return ""
	if c.has("skill"):
		return String(c["skill"])
	return String(POSITION_SKILL.get(String(c.get("position", "")), ""))


static func default_subclass(class_id: String) -> String:
	var subs: Dictionary = CLASSES.get(class_id, {}).get("subclasses", {})
	for k in subs:
		return String(k)
	return ""


static func subclass_ids(class_id: String) -> Array:
	return CLASSES.get(class_id, {}).get("subclasses", {}).keys()


static func subclass_label(class_id: String, sub_id: String) -> String:
	var subs: Dictionary = CLASSES.get(class_id, {}).get("subclasses", {})
	return String(subs.get(sub_id, {}).get("label", sub_id))


static func subclass_trait(class_id: String, sub_id: String) -> Dictionary:
	return CLASSES.get(class_id, {}).get("subclasses", {}).get(sub_id, {}).get("trait", {})


static func subclass_ability(class_id: String, sub_id: String) -> Dictionary:
	return CLASSES.get(class_id, {}).get("subclasses", {}).get(sub_id, {}).get("ability", {})


## Class-level passive 고유 특성 metadata (e.g. 센티넬 제압 사격 suppression). {} if none.
static func class_passive(class_id: String) -> Dictionary:
	return CLASSES.get(class_id, {}).get("passive", {})


## Class-level active ability shared by all subclasses (e.g. 브리처 파괴 공작). {} if none.
static func class_ability(class_id: String) -> Dictionary:
	return CLASSES.get(class_id, {}).get("class_ability", {})


## Human-readable display info per ability id: {name, target, range}. For the prep info panel.
const ABILITY_INFO: Dictionary = {
	"grenade": {"name": "수류탄 투척", "target": "적 광역", "range": "220"},
	"flash_ammo": {"name": "섬광 탄약", "target": "무작위 적 3", "range": "전체"},
	"pierce_ammo": {"name": "관통 탄환", "target": "최근접 적", "range": "단일"},
	"charge_dash": {"name": "돌진", "target": "최근접 적", "range": "돌진"},
	"rally_flag": {"name": "깃발 전개", "target": "아군 광역", "range": "200"},
	"bombardment": {"name": "지정 포격", "target": "적 광역(최저체력)", "range": "150"},
	"heal_turret": {"name": "치유 포탑", "target": "전체 아군", "range": "전체"},
	"bio_radiation": {"name": "생체 방사", "target": "적/아군 광역", "range": "150"},
	"inspire": {"name": "고취", "target": "최저체력 아군", "range": "단일"},
	"demolition": {"name": "파괴 공작", "target": "적 광역", "range": "기술×1.5"},
	"tactical_move": {"name": "전술 기동", "target": "최근접 적", "range": "돌진"},
	"smoke_grenade": {"name": "연막 유탄", "target": "최고공격 적", "range": "사거리×0.75"},
	"fallout_spray": {"name": "낙진 분사", "target": "적 광역", "range": "사거리×0.8"},
	"dynamic_net": {"name": "동적 네트워킹", "target": "아군 1", "range": "단일"},
	"static_format": {"name": "정적 포매팅", "target": "전체 적", "range": "전체"},
	"repair_facility": {"name": "시설 수리", "target": "최저내구 시설", "range": "단일"},
	"point_mark": {"name": "지점 표시", "target": "적 광역", "range": "마커"},
	"forced_record": {"name": "강제 필사", "target": "최근접 적", "range": "단일"},
	"air_bombard": {"name": "공중 포격", "target": "무작위 적 광역", "range": "사거리"},
	"relief_drop": {"name": "구호품 낙하", "target": "최저체력 아군", "range": "다수"},
	"lead_drop": {"name": "선두 지휘", "target": "전체 아군", "range": "버프"},
	"assault": {"name": "암습", "target": "최근접 적", "range": "돌진"},
	"sec_breach": {"name": "보안 탈취", "target": "최근접 적", "range": "단일"},
	"smoke_veil": {"name": "위장 연막탄", "target": "주변 아군", "range": "사거리×0.5"},
	"gravity_release": {"name": "인력 방출", "target": "최근접 적", "range": "단일+밀쳐냄"},
	"field_collapse": {"name": "역장 붕괴", "target": "적 광역(최대체력)", "range": "기술×1.5"},
}


static func ability_display(ability_id: String) -> Dictionary:
	return ABILITY_INFO.get(ability_id, {})


## Per-subclass modifiers to the class passive (센티넬 군림자/조종자/분쇄자). {} if none.
static func subclass_supp(class_id: String, sub_id: String) -> Dictionary:
	return CLASSES.get(class_id, {}).get("subclasses", {}).get(sub_id, {}).get("supp", {})


static func base_mods(class_id: String) -> Dictionary:
	return CLASSES.get(class_id, {}).get("base", {})


## Tier is 1-based (1/2/3). Returns {} if out of range.
static func tier_mods(class_id: String, subclass_id: String, tier: int) -> Dictionary:
	var subs: Dictionary = CLASSES.get(class_id, {}).get("subclasses", {})
	var tiers: Array = subs.get(subclass_id, {}).get("tiers", [])
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
