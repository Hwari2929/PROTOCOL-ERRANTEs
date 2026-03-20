class_name DialogueEntry
extends RefCounted
## 단일 대화 항목 헬퍼
##
## DialogueData.entries에 저장되는 Dictionary의 스키마 정의.
## 실제 저장은 Dictionary로 하되, 이 클래스를 빌더로 사용.
##
## Dictionary 구조:
## {
##   "npc_line": String,           — NPC가 말하는 대사
##   "responses": [                — 플레이어 응답 선택지
##     {
##       "text": String,           — 응답 텍스트
##       "effect": StringName,     — 효과 ("patience_up", "satisfaction_up", "none")
##       "effect_value": int,      — 효과 수치
##       "next_context": StringName — 응답 후 이어질 문맥 (비어있으면 대화 종료)
##     }
##   ]
## }


## 대화 항목 딕셔너리 생성.
static func create(npc_line: String, responses: Array[Dictionary] = []) -> Dictionary:
	return {
		"npc_line": npc_line,
		"responses": responses,
	}


## 응답 선택지 딕셔너리 생성.
static func response(
	text: String,
	effect: StringName = &"none",
	effect_value: int = 0,
	next_context: StringName = &""
) -> Dictionary:
	return {
		"text": text,
		"effect": effect,
		"effect_value": effect_value,
		"next_context": next_context,
	}
