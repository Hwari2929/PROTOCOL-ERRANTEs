extends Node
## 공명도 / 공명 등급 / 에너지 크레딧 경제.
##
## Energy credits (c) are earned from combat. Spending credits via RESONATE adds an
## EQUAL amount of 공명도 (resonance points); when accumulated points cross the grade
## thresholds the resonance grade rises (per GDD: grade 2=8, 3=12, 4=24, 5=40, cumulative).

signal grade_changed(new_grade: int)
signal credits_changed(new_credits: int)
signal resonance_changed(points: int)

var points: int = 0    # 공명도 (bought with credits)
var credits: int = 0   # 에너지 크레딧 (earned in combat)
var grade: int = 1


## Cumulative 공명도 required to REACH grade g.
func threshold_for(g: int) -> int:
	match g:
		0, 1: return 0
		2: return 8
		3: return 12
		4: return 24
		5: return 40
		_: return 9999


## Earn energy credits (combat reward).
func gain_credits(amount: int) -> void:
	credits += maxi(0, amount)
	credits_changed.emit(credits)


## Back-compat alias used by older callers: now simply earns credits (no auto grade).
func add_resonance(amount: int) -> void:
	gain_credits(amount)


## Spend ALL energy credits to gain an equal amount of 공명도, then raise the grade
## across any thresholds crossed. Returns the number of grades gained.
func resonate_all() -> int:
	if credits <= 0:
		return 0
	points += credits
	credits = 0
	credits_changed.emit(credits)
	resonance_changed.emit(points)
	var gained: int = 0
	while grade < 5 and points >= threshold_for(grade + 1):
		grade += 1
		gained += 1
		grade_changed.emit(grade)
	return gained


func can_resonate() -> bool:
	return credits > 0


func current_grade() -> int:
	return grade


func current_credits() -> int:
	return credits


func current_points() -> int:
	return points
