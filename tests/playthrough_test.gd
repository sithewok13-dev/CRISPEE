extends Node
## Headless playthrough of "The Delivery" using the real systems: physics,
## hop detection, the human's routines, and the puzzle. Proves the slice is
## solvable and that saving round-trips.
##
## Run:  godot --headless --path . --fixed-fps 60 res://tests/playthrough_test.tscn

var main: Main
var failures := 0
var _completed := false


func _ready() -> void:
	WorldState.autosave = false
	Main.skip_title = true
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	GameEvents.slice_completed.connect(func() -> void: _completed = true)
	await _run()
	print("\n%s: %d failure(s)" % ["PASSED" if failures == 0 else "FAILED", failures])
	get_tree().quit(1 if failures > 0 else 0)


func _run() -> void:
	var p := main.player
	var level := main.level
	await _frames(30)
	_check("starts on the couch", absf(p.global_position.y - 0.45) < 0.03 and p.is_on_floor(),
			"y=%.3f" % p.global_position.y)

	# Couch seat is out of hop range from the floor.
	p.teleport(Vector3(-1.6, 0.0, 1.25), PI)
	await _frames(5)
	_check("couch is too high to hop from the floor", p.hop_target == null)

	# Pet stairs: walk up them.
	p.teleport(Vector3(-1.05, 0.0, 0.7), PI)
	main.rig.yaw = PI
	InputRouter.touch_move = Vector2(0, -0.6)
	await _frames(150)
	InputRouter.touch_move = Vector2.ZERO
	_check("walks up the pet stairs onto the couch", p.global_position.y > 0.43,
			"y=%.3f" % p.global_position.y)
	main.rig.yaw = 0.0

	# Ordinary mark against the west wall.
	p.teleport(Vector3(-2.82, 0.0, 0.6), 0.0)
	await _frames(5)
	p.do_mark()
	await _frames(90)
	_check("ordinary mark on the wall counts", WorldState.ordinary_marks == 1)

	# Open floor: nothing to mark.
	p.teleport(Vector3(0.6, 0.0, -0.8), 0.0)
	await _frames(5)
	p.do_mark()
	await _frames(70)
	_check("open floor is not markable", WorldState.ordinary_marks == 1)

	# The shelf is out of reach before the box moves.
	p.teleport(Vector3(-2.3, 0.0, -1.3), PI * 0.5)
	await _frames(5)
	_check("bookshelf is too high from the floor", p.hop_target == null)

	# Claim the delivery box.
	p.teleport(Vector3(0.9, 0.0, -1.62), 0.0)
	await _frames(5)
	p.do_mark()
	await _frames(100)
	_check("box claim sets the flag", WorldState.has_flag("box_claimed"))
	_check("box claim is recorded", WorldState.is_claimed("box"))
	p.teleport(Vector3(-0.5, 0.0, 1.0), 0.0)  # out of the human's way
	await _until(func() -> bool: return not level.human.busy(), 40.0)
	_check("human moves the box beside the shelf",
			level.box_root.global_position.distance_to(LivingRoom.BOX_SHELF_SPOT) < 0.02,
			str(level.box_root.global_position))
	_check("box is labelled", level.box_label.visible)
	_check("human sits back down", level.human.seated)

	# Hop onto the box, then onto the shelf.
	p.teleport(Vector3(-1.85, 0.0, -1.3), PI * 0.5)
	await _frames(5)
	_check("can hop onto the claimed box", p.hop_target != null)
	p.do_action()
	await _frames(45)
	_check("lands on the box", absf(p.global_position.y - 0.25) < 0.03, "y=%.3f" % p.global_position.y)
	await _frames(3)
	_check("can hop from box to shelf", p.hop_target != null)
	p.do_action()
	await _frames(45)
	_check("lands on the shelf", absf(p.global_position.y - 0.5) < 0.03, "y=%.3f" % p.global_position.y)

	# Grab the leash.
	await _frames(3)
	p.do_action()
	await _frames(5)
	_check("grabs the leash", p.carried == level.leash)

	# Give it to the human.
	p.teleport(Vector3(1.45, 0.0, 0.6), -PI * 0.5)
	await _frames(5)
	p.do_action()
	await _frames(5)
	_check("human takes the leash", p.carried == null and WorldState.has_flag("door_open"))
	await _until(func() -> bool: return not level.human.busy(), 20.0)
	_check("door opens", absf(level.door_hinge.rotation.y - deg_to_rad(-100.0)) < 0.05,
			"rot=%.2f" % level.door_hinge.rotation.y)

	# Save round-trip.
	var saved := WorldState.to_dict()
	var restored := JSON.parse_string(JSON.stringify(saved)) as Dictionary
	WorldState.reset()
	_check("save restores", WorldState.from_dict(restored) and WorldState.has_flag("door_open")
			and WorldState.is_claimed("box"))

	# Walk out to the sausage.
	p.teleport(Vector3(1.8, 0.0, -3.0), 0.0)
	main.rig.yaw = 0.0
	InputRouter.touch_move = Vector2(0, -0.8)
	await _until(func() -> bool: return _completed, 8.0)
	InputRouter.touch_move = Vector2.ZERO
	_check("reaching the sausage completes the slice", _completed)


func _check(name: String, ok: bool, detail: String = "") -> void:
	if not ok:
		failures += 1
	print("%s  %s%s" % ["PASS" if ok else "FAIL", name, "" if ok or detail == "" else "  (" + detail + ")"])


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _until(cond: Callable, seconds: float) -> void:
	var frames := int(seconds * 60.0)
	for i in frames:
		if cond.call():
			return
		await get_tree().physics_frame
