class_name RecipeStep
extends Resource
## 레시피의 단일 단계
##
## 플레이어에게 제시되는 하나의 선택 화면.
## 예: "컵을 선택하세요" → [작은 컵, 중간 컵]

## 단계 안내 텍스트 (UI에 표시)
@export var prompt_text: String = ""

## 선택지 목록
@export var choices: Array[Resource] = []  ## Array[RecipeChoice]


## 선택지 수 반환.
func get_choice_count() -> int:
	return choices.size()


## 특정 선택지 반환.
func get_choice(index: int) -> Resource:
	if index < 0 or index >= choices.size():
		return null
	return choices[index]


## ID로 선택지 검색.
func find_choice(choice_id: StringName) -> Resource:
	for choice in choices:
		if choice and choice.get("id") == choice_id:
			return choice
	return null
