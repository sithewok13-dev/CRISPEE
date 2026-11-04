extends Node3D
## Wires the level, the dog, camera, HUD, touch controls and powers together.

var level: LivingRoom
var dog: Crispee
var rig: Node3D
var hud: CanvasLayer
var touch: CanvasLayer
var vision: CanvasLayer
var _power_held := false
var _finished := false

func _ready() -> void:
	Game.start_level("The living room", 4)
	level = LivingRoom.new(); level.name = "Level"; add_child(level); level.build()
	dog = Crispee.new(); dog.name = "Crispee"; dog.position = Vector3(-0.5, 0.05, 1.2)
	add_child(dog)
	rig = load("res://scripts/camera_rig.gd").new(); rig.name = "CameraRig"; add_child(rig)
	rig.target = dog; rig.yaw = 0.0  # look toward the couch at the start
	rig.global_position = dog.global_position
	hud = load("res://scripts/hud.gd").new(); hud.name = "HUD"; add_child(hud); hud.refresh()
	vision = load("res://scripts/pee_vision.gd").new(); vision.name = "PeeVision"; add_child(vision)
	touch = load("res://scripts/touch_controls.gd").new(); touch.name = "Touch"; add_child(touch)
	touch.stick_changed.connect(func(d): dog.input_dir = d)
	touch.button_pressed.connect(_on_button)
	touch.button_released.connect(func(n): if n == "POWER": _power_held = false)
	touch.camera_nudge.connect(func(a): rig.nudge(a))
	dog.prompt_changed.connect(func(t): hud.set_prompt(t))
	Game.claimed.connect(_on_claimed)
	for s in Game.spots:
		s.body_entered.connect(func(b): if b == dog: dog.current_spot = s)
		s.body_exited.connect(func(b): if b == dog and dog.current_spot == s: dog.current_spot = null)
	level.water.body_entered.connect(func(b): if b == dog: dog.near_water = true)
	level.water.body_exited.connect(func(b): if b == dog: dog.near_water = false)
	level.exit_zone.body_entered.connect(func(b): if b == dog: _try_exit())
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots"):
			var t: Node = load("res://scripts/autotest.gd").new(); t.name = "AutoTest"; add_child(t)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pee"): _on_button("PEE")
	elif event.is_action_pressed("jump"): dog.want_jump = true
	elif event.is_action_pressed("act"): _on_button("ACT")
	elif event.is_action_pressed("power"): _on_button("POWER")

func _on_button(n: String) -> void:
	match n:
		"PEE":
			if not dog.try_pee() and dog.current_spot == null:
				hud.show_toast("Not here. Crispee has standards.", 1.6)
		"JUMP": dog.want_jump = true
		"ACT":
			var r := dog.try_act()
			if r == "drink": hud.show_toast("Refilled.", 1.5)
			elif r == "bark": pass
		"POWER":
			_power_held = true
			if vision.activate():
				hud.set_vision(true)
				get_tree().create_timer(vision.duration).timeout.connect(func(): hud.set_vision(false))
			else:
				hud.show_toast("Pee Vision is recharging.", 1.2)

func _on_claimed(spot: ClaimSpot) -> void:
	hud.show_toast("CLAIMED: %s\n%s" % [spot.label, spot.reaction], 5.5)
	if Game.owned_count() >= Game.par and not Game.world.has("door_open"):
		pass

func _try_exit() -> void:
	if _finished: return
	if not Game.world.has("door_open"):
		return
	if Game.owned_count() < Game.par:
		hud.show_toast("Not yet. Par is %d claims." % Game.par, 2.0)
		return
	_finished = true
	Game.finish_level()
