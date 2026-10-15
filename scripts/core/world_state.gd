extends Node
## Persistent game state: story flags, Crispee's claims, and a checkpoint.
## Puzzles read and write flags; nothing else needs to know how saving works.

const SAVE_PATH := "user://crispee_save.json"
const SAVE_VERSION := 1

var flags: Dictionary = {}
var claims: Array[String] = []
var ordinary_marks := 0
var checkpoint_position := Vector3.ZERO
var has_checkpoint := false

## Set by the level so a save can record where Crispee is standing.
var player_position_provider: Callable

## Tests turn this off so they never touch the real save file.
var autosave := true


func reset() -> void:
	flags.clear()
	claims.clear()
	ordinary_marks = 0
	has_checkpoint = false


func has_flag(flag: String) -> bool:
	return bool(flags.get(flag, false))


func set_flag(flag: String, value: Variant = true) -> void:
	if flags.get(flag) == value:
		return
	flags[flag] = value
	GameEvents.flag_changed.emit(flag, value)
	save_game()


func add_claim(id: String) -> void:
	if id in claims:
		return
	claims.append(id)
	save_game()


func is_claimed(id: String) -> bool:
	return id in claims


func to_dict() -> Dictionary:
	var data := {
		"version": SAVE_VERSION,
		"flags": flags,
		"claims": claims,
		"ordinary_marks": ordinary_marks,
	}
	if player_position_provider.is_valid():
		var p: Vector3 = player_position_provider.call()
		data["checkpoint"] = [p.x, p.y, p.z]
	return data


func from_dict(data: Dictionary) -> bool:
	if int(data.get("version", 0)) != SAVE_VERSION:
		return false
	reset()
	flags = data.get("flags", {})
	for c in data.get("claims", []):
		claims.append(str(c))
	ordinary_marks = int(data.get("ordinary_marks", 0))
	var cp: Array = data.get("checkpoint", [])
	if cp.size() == 3:
		checkpoint_position = Vector3(cp[0], cp[1], cp[2])
		has_checkpoint = true
	return true


func save_game() -> void:
	if not autosave:
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write save: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(to_dict()))


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	return from_dict(parsed)


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
