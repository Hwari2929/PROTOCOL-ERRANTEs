extends Node
## 상태 효과 컨트롤러 (유닛별 자식 노드)
## Manages stacked status effects (출혈/연소/중독/부식/표적/초과 체력) with per-second
## ticks and durations, applied to the owning Unit (get_parent()).

var shield: int = 0
var _effects: Dictionary = {}
var _timer: float = 0.0

func apply_status(id: String, stacks: int, duration: float, per_sec_per_stack: float, dtype: String) -> void:
	var existing: Dictionary = _effects.get(id, { "stacks": 0, "time_left": 0.0, "per_sec": 0.0, "dtype": "", "max_stacks": 5 })
	var max_stacks: int = int(existing.get("max_stacks", 5))
	var current_stacks: int = int(existing.get("stacks", 0))
	var current_time: float = float(existing.get("time_left", 0.0))
	
	var new_stacks: int = mini(current_stacks + stacks, max_stacks)
	var new_time_left: float = maxf(current_time, duration)
	
	_effects[id] = {
		"stacks": new_stacks,
		"time_left": new_time_left,
		"per_sec": per_sec_per_stack,
		"dtype": dtype,
		"max_stacks": max_stacks
	}

func tick(delta: float) -> void:
	_timer += delta
	var ids_to_remove: Array[String] = []
	
	if _timer >= 1.0:
		_timer -= 1.0
		var owner := get_parent()
		if owner and owner.has_method("take_damage"):
			for id in _effects:
				var effect: Dictionary = _effects[id]
				var dtype: String = str(effect.get("dtype", ""))
				if dtype in ["physical", "chemical"]:
					var stacks: int = int(effect.get("stacks", 0))
					var per_sec: float = float(effect.get("per_sec", 0.0))
					var dmg: int = int(round(per_sec * float(stacks)))
					owner.take_damage(dmg)
	
	for id in _effects:
		var effect: Dictionary = _effects[id]
		var time_left: float = float(effect.get("time_left", 0.0))
		time_left -= delta
		effect["time_left"] = time_left
		if time_left <= 0.0:
			ids_to_remove.append(id)
	
	for id in ids_to_remove:
		_effects.erase(id)

func apply_bleed(stacks: int, dur: float) -> void:
	apply_status("bleed", stacks, dur, 5.0, "physical")

func apply_burn(stacks: int, dur: float) -> void:
	apply_status("burn", stacks, dur, 5.0, "physical")

func apply_poison(stacks: int, dur: float) -> void:
	apply_status("poison", stacks, dur, 6.0, "chemical")

func add_shield(amount: int) -> void:
	shield += amount

func shield_amount() -> int:
	return shield

func absorb(amount: int) -> int:
	var remaining: int = amount
	if shield > 0:
		var absorbed: int = mini(shield, amount)
		shield -= absorbed
		remaining -= absorbed
	return remaining

## 강조 표시(highlight)/표적(target) 등 받는 피해 증가 디버프 배율. 1.0 = 증가 없음.
## highlight = +15% (마커의 회피/효과저항 감소를 전투 피해로 환산), vulnerable는 추가 누적.
func damage_taken_mult() -> float:
	var m: float = 1.0
	if _effects.has("highlight"):
		m += 0.15
	if _effects.has("vulnerable"):
		m += 0.20 * float(maxi(1, int(_effects["vulnerable"].get("stacks", 1))))
	return m

func has_effect(id: String) -> bool:
	return _effects.has(id)

func stacks_of(id: String) -> int:
	if _effects.has(id):
		return int(_effects[id].get("stacks", 0))
	return 0