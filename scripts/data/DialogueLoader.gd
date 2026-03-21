class_name DialogueLoader
extends RefCounted
## JSON 파일에서 DialogueData를 로드하는 유틸리티
##
## JSON 스키마:
## {
##   "id": "dlg_amundsen",
##   "entries": {
##     "greeting": [
##       {
##         "npc_line": "...여기가 그 바인가.",
##         "tag": "opening",
##         "responses": [
##           {
##             "text": "(고개를 끄덕인다)",
##             "effect": "patience_up",
##             "effect_value": 5,
##             "next_context": ""
##           }
##         ]
##       }
##     ],
##     "waiting": [...],
##     "idle": [...],
##     "eating": [...],
##     "farewell": [...],
##     "custom_branch_name": [...]
##   }
## }
##
## JSON 파일 경로: res://resources/dialogues/<customer_id>.json


## JSON 파일에서 DialogueData를 로드.
static func load_from_file(path: String) -> DialogueData:
	if not FileAccess.file_exists(path):
		push_warning("DialogueLoader: 파일을 찾을 수 없음 '%s'" % path)
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("DialogueLoader: 파일 열기 실패 '%s'" % path)
		return null

	var text := file.get_as_text()
	file.close()

	return load_from_string(text)


## JSON 문자열에서 DialogueData를 로드.
static func load_from_string(json_text: String) -> DialogueData:
	var json := JSON.new()
	var err := json.parse(json_text)
	if err != OK:
		push_warning("DialogueLoader: JSON 파싱 실패 — %s" % json.get_error_message())
		return null

	var data: Dictionary = json.data
	return _parse_dialogue_data(data)


## 손님 ID로 기본 경로에서 대화 데이터 로드.
static func load_for_customer(customer_id: StringName) -> DialogueData:
	var path := "res://resources/dialogues/%s.json" % customer_id
	return load_from_file(path)


static func _parse_dialogue_data(data: Dictionary) -> DialogueData:
	var dlg := DialogueData.new()
	dlg.id = StringName(data.get("id", ""))

	var entries: Dictionary = data.get("entries", {})
	for context_key: String in entries:
		var context := StringName(context_key)
		var entry_list: Array = entries[context_key]
		for entry_dict: Dictionary in entry_list:
			var entry := _parse_entry(entry_dict)
			dlg.add_entry(context, entry)

	return dlg


static func _parse_entry(data: Dictionary) -> Dictionary:
	var responses: Array[Dictionary] = []
	var raw_responses: Array = data.get("responses", [])
	for resp_dict: Dictionary in raw_responses:
		responses.append({
			"text": str(resp_dict.get("text", "")),
			"effect": StringName(resp_dict.get("effect", "none")),
			"effect_value": int(resp_dict.get("effect_value", 0)),
			"next_context": StringName(resp_dict.get("next_context", "")),
		})

	return {
		"npc_line": str(data.get("npc_line", "")),
		"tag": StringName(data.get("tag", "opening")),
		"responses": responses,
	}
