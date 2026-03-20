class_name RecipeData
extends Resource
## 단계별 음료/음식 제조 레시피
##
## 각 단계(RecipeStep)에서 플레이어가 선택지를 고르면
## 최종 선택 조합에 따라 품질/만족도 보너스가 결정된다.
##
## 예: 얼음물 레시피
##   Step 1: 컵 선택 (small_cup, medium_cup)
##   Step 2: 음료 선택 (water, juice)
##   Step 3: 얼음 양 선택 (none, crushed, cubed)

@export var id: StringName
@export var display_name: String
@export var steps: Array[Resource] = []  ## Array[RecipeStep]

## 정답 조합 (step_index → choice_id). 이 조합이면 최대 품질.
@export var ideal_combination: Dictionary = {}

## 기본 제작 시간 (선택 완료 후 마무리 연출용, 초)
@export var finish_time: float = 0.5


## 단계 수 반환.
func get_step_count() -> int:
	return steps.size()


## 특정 단계 반환.
func get_step(index: int) -> Resource:
	if index < 0 or index >= steps.size():
		return null
	return steps[index]


## 선택 조합의 품질 점수 계산 (0.0~1.0).
## choices: {step_index: choice_id}
func evaluate_quality(choices: Dictionary) -> float:
	if ideal_combination.is_empty():
		return 1.0
	var matches := 0
	var total := ideal_combination.size()
	for step_idx in ideal_combination:
		if choices.get(step_idx, &"") == ideal_combination[step_idx]:
			matches += 1
	return float(matches) / float(total) if total > 0 else 1.0
