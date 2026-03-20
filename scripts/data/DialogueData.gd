class_name DialogueData
extends Resource
## 손님 대화 데이터
##
## 문맥별(context) 대화 항목 묶음.
## 각 항목: NPC 대사 + 플레이어 응답 선택지 + 효과.
##
## context 종류:
##   "greeting"  — 첫 착석 시
##   "waiting"   — 주문 대기 중
##   "idle"      — IDLE 상태
##   "eating"    — 소비 중
##   "farewell"  — 퇴장 시

@export var id: StringName
## context → Array[DialogueEntry] 매핑. 코드에서 딕셔너리로 관리.
@export var entries: Dictionary = {}


## 특정 문맥의 대화 목록 반환.
func get_entries(context: StringName) -> Array:
	return entries.get(context, [])


## 특정 문맥에서 랜덤 대화 하나 선택.
func pick_entry(context: StringName) -> Dictionary:
	var pool: Array = entries.get(context, [])
	if pool.is_empty():
		return {}
	return pool.pick_random()


## 대화 항목 추가 (코드에서 빌드 시 사용).
func add_entry(context: StringName, entry: Dictionary) -> void:
	if context not in entries:
		entries[context] = []
	entries[context].append(entry)
