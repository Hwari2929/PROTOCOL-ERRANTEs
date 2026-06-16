extends Node

signal grade_changed(new_grade: int)
signal level_up_ready(new_grade: int)

var points: int = 0
var credits: int = 0
var grade: int = 1

func threshold_for(g: int) -> int:
	match g:
		0, 1: return 0
		2: return 8
		3: return 12
		4: return 24
		5: return 40
		_: return 9999

func add_resonance(amount: int) -> void:
	points += amount
	credits += amount
	while grade < 5 and points >= threshold_for(grade + 1):
		grade += 1
		grade_changed.emit(grade)
		level_up_ready.emit(grade)

func can_grade_up() -> bool:
	return grade < 5 and points >= threshold_for(grade + 1)

func current_grade() -> int:
	return grade