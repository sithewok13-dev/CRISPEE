extends Node
## Scripted run for CI: plays through the living room and saves screenshots.
## Run: godot --path game --rendering-driver opengl3 -- --shots=out_dir

var out := "shots"
var main: Node3D
var n := 0

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="): out = a.substr(8)
	DirAccess.make_dir_recursive_absolute(out)
	main = get_tree().current_scene
	_run()

func _shot(tag: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	n += 1
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%02d_%s.png" % [out, n, tag])
	print("shot ", n, " ", tag)

func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout

func _wait_until(cond: Callable, max_sec: float, what: String) -> bool:
	var t := 0.0
	while t < max_sec:
		if cond.call():
			return true
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	print("TIMEOUT waiting for ", what)
	return false

func _pee_at(dog: Crispee, key: String) -> void:
	await _wait_until(func(): return dog.current_spot != null and dog.current_spot.key == key, 4.0, "spot " + key)
	main._on_button("PEE")
	await _wait_until(func(): return Game.owned.has(key), 2.0, "claim " + key)

func _run() -> void:
	await _wait(0.4)
	var dog: Crispee = main.dog
	var level: LivingRoom = main.level
	await _shot("start")
	# 1. physics: run toward the couch and jump
	dog.input_dir = Vector2(0, -1)
	await _wait(0.8)
	# look toward -z for the couch section
	var y0 := dog.global_position.y
	dog.want_jump = true
	await _wait(0.3)
	print("jump rise ", dog.global_position.y - y0)
	await _shot("running")
	dog.input_dir = Vector2.ZERO
	await _wait(0.6)
	# 2. slipper claim
	dog.global_position = Vector3(-2.0, 0.05, 0.9); dog.velocity = Vector3.ZERO
	await _pee_at(dog, "slipper")
	await _wait(0.4)
	await _shot("claim_slipper")
	await _wait(0.8)
	# 3. onto the couch, claim the cushion, then the box
	main.rig.yaw = 0.0; main.rig.global_position = Vector3(0.5, 0.8, -2.35)
	dog.global_position = Vector3(0.5, 0.52, -2.35); dog.velocity = Vector3.ZERO
	await _pee_at(dog, "cushion")
	await _wait(0.5)
	await _shot("couch")
	await _wait(0.8)
	main.rig.yaw = 0.0
	dog.global_position = Vector3(1.75, 0.65, -2.3); dog.velocity = Vector3.ZERO
	await _pee_at(dog, "acbox")
	await _wait(0.8)
	await _shot("claim_box")
	# 4. pee vision while Dad carries the box
	main._on_button("POWER")
	await _wait(1.0)
	await _shot("pee_vision")
	await _wait_until(func(): return level.ac_box.position.x > 2.9 and level.dad.carrying == null, 20.0, "Dad placing the box")
	await _wait(0.5)
	await _shot("dad_moved_box")
	# 5. drink, then the thermostat from the moved box
	dog.global_position = Vector3(2.8, 0.05, 1.9); dog.velocity = Vector3.ZERO
	await _wait(0.4)
	main._on_button("ACT")
	await _wait(0.3)
	main.rig.yaw = PI * 0.5
	dog.global_position = Vector3(2.95, 0.65, -1.2); dog.velocity = Vector3.ZERO
	await _wait(0.5)
	await _pee_at(dog, "thermostat")
	await _wait(0.8)
	await _shot("claim_thermostat")
	await _wait_until(func(): return level.door.position.x < -2.1, 20.0, "Dad opening the door")
	await _wait(0.3)
	await _shot("door_open")
	main.rig.yaw = PI; main.rig.global_position = Vector3(-1.5, 0.3, 1.0)
	await _wait(0.4)
	await _shot("door_from_inside")
	# 6. exit through the opened door
	main.rig.yaw = PI
	dog.global_position = Vector3(-1.4, 0.05, 2.6); dog.velocity = Vector3.ZERO
	await _wait(0.3)
	dog.global_position = Vector3(-1.4, 0.05, 3.3); dog.velocity = Vector3.ZERO
	await _wait_until(func(): return Game.finished, 4.0, "finish")
	await _wait(0.3)
	await _shot("exit")
	print("owned ", Game.owned_count(), " finished ", Game.finished, " time ", Game.time_sec)
	await _wait(0.3)
	get_tree().quit()
