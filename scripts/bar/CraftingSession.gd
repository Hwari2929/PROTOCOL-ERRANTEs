class_name CraftingSession
extends RefCounted
## 진행 중인 단계별 제조 세션
##
## MenuSystem이 레시피가 있는 주문을 받으면 CraftingSession을 생성.
## UI(CraftingPanel)가 이 세션을 참조하여 단계별 선택지를 표시.
##
## 사용 흐름:
##   1. MenuSystem → create session with RecipeData + order
##   2. UI → get_current_step() 으로 현재 단계 표시
##   3. 플레이어 선택 → select_choice(choice_id)
##   4. 모든 단계 완료 → is_completed() == true
##   5. MenuSystem → finalize() → 서빙

signal step_advanced(step_index: int, step: RecipeStep)
signal choice_selected(step_index: int, choice_id: StringName)
signal session_completed(quality: float, choices: Dictionary)

var recipe: RecipeData = null
var order: Dictionary = {}

## 현재 단계 인덱스
var current_step_index: int = 0
## 각 단계에서의 선택 결과 {step_index: choice_id}
var choices: Dictionary = {}
## 완료 여부
var completed: bool = false
## 최종 품질 (0.0~1.0)
var quality: float = 0.0
## 선택지 보정 합산
var total_satisfaction_modifier: int = 0
var total_price_modifier: int = 0


func _init(p_recipe: RecipeData, p_order: Dictionary) -> void:
	recipe = p_recipe
	order = p_order


## 현재 단계의 RecipeStep 반환. 완료 시 null.
func get_current_step() -> RecipeStep:
	if completed or recipe == null:
		return null
	return recipe.get_step(current_step_index) as RecipeStep


## 현재 단계의 선택지 목록 반환.
func get_current_choices() -> Array[RecipeChoice]:
	var step := get_current_step()
	if step == null:
		return []
	var result: Array[RecipeChoice] = []
	for choice in step.choices:
		if choice is RecipeChoice:
			result.append(choice)
	return result


## 플레이어가 선택지를 고름.
func select_choice(choice_id: StringName) -> bool:
	var step := get_current_step()
	if step == null:
		return false

	# 선택지 유효성 확인
	var found_choice: RecipeChoice = null
	for choice in step.choices:
		if choice is RecipeChoice and choice.id == choice_id:
			found_choice = choice
			break

	if found_choice == null:
		return false

	choices[current_step_index] = choice_id
	total_satisfaction_modifier += found_choice.satisfaction_modifier
	total_price_modifier += found_choice.price_modifier
	choice_selected.emit(current_step_index, choice_id)

	current_step_index += 1
	if current_step_index >= recipe.get_step_count():
		_finalize()
	else:
		var next_step := get_current_step()
		if next_step:
			step_advanced.emit(current_step_index, next_step)

	return true


## 남은 단계 수.
func get_remaining_steps() -> int:
	if recipe == null:
		return 0
	return max(recipe.get_step_count() - current_step_index, 0)


## 진행률 (0.0~1.0).
func get_progress() -> float:
	if recipe == null or recipe.get_step_count() == 0:
		return 1.0
	return float(current_step_index) / float(recipe.get_step_count())


## 완료 여부.
func is_completed() -> bool:
	return completed


func _finalize() -> void:
	completed = true
	quality = recipe.evaluate_quality(choices)
	session_completed.emit(quality, choices)
