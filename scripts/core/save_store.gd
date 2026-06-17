extends Node
class_name SaveStore
## Minimal persistent meta record (user://). Tracks runs / wins / best nodes cleared.
## Lightweight static helper (the GDD's full SaveManager can supersede later).

const PATH: String = "user://pe_record.json"


static func load_record() -> Dictionary:
	var base: Dictionary = {"runs": 0, "wins": 0, "best_nodes": 0}
	if not FileAccess.file_exists(PATH):
		return base
	var f: FileAccess = FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return base
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return base
	var d: Dictionary = parsed
	base["runs"] = int(d.get("runs", 0))
	base["wins"] = int(d.get("wins", 0))
	base["best_nodes"] = int(d.get("best_nodes", 0))
	return base


static func record_run(nodes_cleared: int, victory: bool) -> void:
	var d: Dictionary = load_record()
	d["runs"] = int(d["runs"]) + 1
	if victory:
		d["wins"] = int(d["wins"]) + 1
	d["best_nodes"] = maxi(int(d["best_nodes"]), nodes_cleared)
	var f: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(d))
		f.close()
