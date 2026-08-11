extends Node

const SAVE_PATH := "user://m1_save.json"
const TEMP_PATH := "user://m1_save.tmp"
const SAVE_VERSION := 1


func load_state() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	if int(parsed.get("version", -1)) != SAVE_VERSION:
		return {}
	var state: Variant = parsed.get("state", {})
	return state if typeof(state) == TYPE_DICTIONARY else {}


func save_state(state: Dictionary) -> void:
	var payload := {"version": SAVE_VERSION, "state": state}
	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("无法写入 M1 自动存档")
		return
	file.store_string(JSON.stringify(payload))
	file.close()
	DirAccess.rename_absolute(TEMP_PATH, SAVE_PATH)


func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
