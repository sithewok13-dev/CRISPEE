extends Node
## Global state: claims, bladder, timer, best times. Autoloaded as `Game`.

signal claimed(spot)
signal world_changed(key)
signal bladder_changed(marks, max_marks)
signal level_finished(time_sec)

const SAVE_PATH := "user://crispee_save.json"

var territory_name := ""
var par := 4
var spots: Array = []           # ClaimSpot nodes, in list order
var owned := {}                  # spot key -> true
var world := {}                  # world-change keys that have happened
var marks := 3
var max_marks := 3
var time_sec := 0.0
var running := false
var finished := false
var best_times := {}

func _ready() -> void:
	_load()

func _process(delta: float) -> void:
	if running and not finished:
		time_sec += delta

func start_level(name: String, level_par: int) -> void:
	territory_name = name
	par = level_par
	spots.clear(); owned.clear(); world.clear()
	marks = max_marks
	time_sec = 0.0
	running = true
	finished = false

func register_spot(spot) -> void:
	spots.append(spot)

func owned_count() -> int:
	return owned.size()

func can_mark() -> bool:
	return marks > 0

func mark(spot) -> bool:
	if owned.has(spot.key) or marks <= 0:
		return false
	marks -= 1
	owned[spot.key] = true
	bladder_changed.emit(marks, max_marks)
	claimed.emit(spot)
	if spot.world_key != "":
		world[spot.world_key] = true
		world_changed.emit(spot.world_key)
	return true

func refill() -> void:
	marks = max_marks
	bladder_changed.emit(marks, max_marks)

func finish_level() -> void:
	if finished:
		return
	finished = true
	running = false
	var prev = best_times.get(territory_name, -1.0)
	if prev < 0.0 or time_sec < prev:
		best_times[territory_name] = time_sec
		_save()
	level_finished.emit(time_sec)

func best_time() -> float:
	return best_times.get(territory_name, -1.0)

func fmt_time(t: float) -> String:
	var m := int(t) / 60
	var s := fmod(t, 60.0)
	return "%02d:%04.1f" % [m, s]

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"best_times": best_times}))

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f:
		var data = JSON.parse_string(f.get_as_text())
		if data is Dictionary and data.has("best_times"):
			best_times = data["best_times"]
