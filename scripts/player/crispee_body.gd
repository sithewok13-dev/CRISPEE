class_name CrispeeBody
extends Node3D
## PLACEHOLDER Crispee, built from primitives and animated procedurally.
## It exists to test scale, readability and feel until the commissioned
## model and rig arrive. Proportions follow the reference video: tiny body,
## thin legs, upright plumed tail, semi-folded blonde ears, scruffy beard.
## By design there is nothing around his middle: no diaper, no band.
##
## The procedural layers (gait, tail, ear springs, head look) are meant to
## survive onto the real rig; the primitive meshes are not.

const CREAM := Color(0.94, 0.89, 0.78)
const CREAM_LIGHT := Color(0.98, 0.95, 0.88)
const BLONDE := Color(0.86, 0.71, 0.47)
const BLONDE_DARK := Color(0.76, 0.58, 0.36)
const NOSE := Color(0.07, 0.06, 0.06)
const EYE := Color(0.11, 0.09, 0.09)

var mouth: Node3D

var _bob: Node3D
var _neck: Node3D
var _head: Node3D
var _ears: Array[Node3D] = []
var _legs: Array[Dictionary] = []  # {hip, knee, front, side}
var _tail: Array[Node3D] = []

var _gait_phase := 0.0
var _tail_phase := 0.0
var _ear_vel := 0.0
var _ear_off := 0.0
var _land_squash := 0.0
var _breath := 0.0
var _idle_look_timer := 2.0
var _idle_look := 0.0

var pose := "idle"
var pose_time := 0.0
## World-space point to glance at (e.g. a nearby interactable), or null.
var look_target: Variant = null


func _ready() -> void:
	_build()


func set_pose(p: String) -> void:
	if p != pose:
		pose = p
		pose_time = 0.0


func land() -> void:
	_land_squash = 1.0


func animate(delta: float, speed: float, on_floor: bool, vertical_velocity: float) -> void:
	pose_time += delta
	_breath += delta * 2.2
	var speed_n := clampf(speed / 2.6, 0.0, 1.0)
	if speed > 0.05:
		_gait_phase += delta * (6.0 + speed * 5.5)
	_tail_phase += delta * (9.0 + speed * 6.0 + (8.0 if pose == "sniff" else 0.0))
	_land_squash = move_toward(_land_squash, 0.0, delta * 5.0)

	# Legs: a trot, diagonal pairs in phase.
	var stride := deg_to_rad(8.0 + 30.0 * speed_n) if speed > 0.05 else 0.0
	for leg in _legs:
		var off: float = 0.0 if (leg.front == (leg.side > 0)) else PI
		var s := sin(_gait_phase + off)
		var hip_x := s * stride
		var knee_x := maxf(0.0, -cos(_gait_phase + off)) * stride * 1.2
		if not leg.front:
			knee_x = -knee_x
		var hip_z := 0.0
		if not leg.front:
			hip_x += 0.25
			knee_x -= 0.45
		if not on_floor or pose == "hop":
			hip_x = deg_to_rad(-35.0) if leg.front else deg_to_rad(35.0)
			knee_x = deg_to_rad(40.0) if leg.front else deg_to_rad(-40.0)
		if (pose == "mark" or pose == "empty") and not leg.front and leg.side > 0:
			hip_z = deg_to_rad(75.0) * minf(pose_time * 5.0, 1.0)
			hip_x = deg_to_rad(15.0)
			knee_x = deg_to_rad(-30.0)
		_approach(leg.hip, Vector3(hip_x, 0.0, hip_z), delta, 22.0)
		_approach(leg.knee, Vector3(knee_x, 0.0, 0.0), delta, 22.0)

	# Body bob, lean and squash.
	var bob_y := absf(sin(_gait_phase)) * 0.008 * speed_n + sin(_breath) * 0.0015
	bob_y -= _land_squash * 0.02
	var body_pitch := clampf(-vertical_velocity * 0.12, -0.4, 0.4) if not on_floor else 0.0
	var body_roll := 0.0
	if pose == "mark" or pose == "empty":
		body_roll = deg_to_rad(7.0)
		bob_y -= 0.01
	if pose == "sniff":
		body_pitch = deg_to_rad(8.0)
		bob_y -= 0.012
	if pose == "bark":
		bob_y += sin(minf(pose_time * 18.0, PI)) * 0.012
	_bob.position.y = lerpf(_bob.position.y, bob_y, minf(delta * 20.0, 1.0))
	_approach(_bob, Vector3(body_pitch, 0.0, body_roll), delta, 12.0)

	# Neck and head.
	var neck_x := deg_to_rad(10.0) + sin(_gait_phase * 2.0) * 0.03 * speed_n
	var head_yaw := 0.0
	match pose:
		"sniff":
			neck_x = deg_to_rad(-62.0) + sin(pose_time * 14.0) * 0.05
		"bark":
			neck_x = deg_to_rad(28.0) - sin(minf(pose_time * 9.0, PI)) * 0.3
		"empty":
			if pose_time > 0.7:
				head_yaw = deg_to_rad(80.0)
				neck_x = deg_to_rad(-5.0)
		"carry":
			neck_x = deg_to_rad(18.0)
	if pose == "idle" and speed < 0.05:
		_idle_look_timer -= delta
		if _idle_look_timer <= 0.0:
			_idle_look_timer = randf_range(1.5, 4.0)
			_idle_look = randf_range(-0.6, 0.6)
		head_yaw = _idle_look
	if look_target != null and pose in ["idle", "carry"]:
		var local: Vector3 = to_local(look_target)
		head_yaw = clampf(atan2(-local.x, -local.z), -0.9, 0.9)
	_approach(_neck, Vector3(neck_x, head_yaw * 0.4, 0.0), delta, 10.0)
	_approach(_head, Vector3(0.0, head_yaw * 0.6, 0.0), delta, 10.0)

	# Ears: a spring kicked by bobbing and landing, so they flop.
	var kick := bob_y * 40.0 + _land_squash * 2.0
	_ear_vel += (-_ear_off * 140.0 - _ear_vel * 9.0 + kick * 30.0) * delta
	_ear_off += _ear_vel * delta
	_ear_off = clampf(_ear_off, -0.6, 0.6)
	for i in _ears.size():
		var ear := _ears[i]
		var side := -1.0 if i == 0 else 1.0
		ear.rotation = Vector3(deg_to_rad(-80.0) + _ear_off, -side * 0.2, side * deg_to_rad(28.0) + _ear_off * side * 0.3)

	# Tail: carried high, wagging; faster when sniffing.
	var wag := 0.35 if pose != "empty" else 0.05
	var tail_lift := deg_to_rad(20.0)
	for i in _tail.size():
		var seg := _tail[i]
		var curl := deg_to_rad(-22.0) if i > 0 else tail_lift
		seg.rotation = Vector3(curl, 0.0, sin(_tail_phase - i * 0.6) * wag * (0.6 + i * 0.25))


func _approach(n: Node3D, target: Vector3, delta: float, rate: float) -> void:
	var t := 1.0 - exp(-rate * delta)
	n.rotation = Vector3(lerp_angle(n.rotation.x, target.x, t), lerp_angle(n.rotation.y, target.y, t),
			lerp_angle(n.rotation.z, target.z, t))


func _build() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2089  # same scruff every time
	_bob = Node3D.new()
	add_child(_bob)

	# Torso: compact (about as long as he is tall), narrow, deeper at the chest.
	Geo.mesh(_bob, Geo.capsule(0.066, 0.24), Vector3(0, 0.19, 0.0), CREAM, Vector3(90, 0, 0))
	Geo.mesh(_bob, Geo.sphere(0.07), Vector3(0, 0.192, -0.075), CREAM, Vector3.ZERO, Vector3(0.95, 1.08, 1.0))
	Geo.mesh(_bob, Geo.sphere(0.064), Vector3(0, 0.195, 0.075), CREAM)
	# A faint blonde wash along the back, as in the video.
	Geo.mesh(_bob, Geo.capsule(0.046, 0.2), Vector3(0, 0.228, 0.005), BLONDE.lerp(CREAM, 0.6),
			Vector3(90, 0, 0), Vector3(1.1, 1.0, 0.55))
	# Scruff: small wiry clumps breaking up the silhouette, mostly on top.
	for i in 18:
		var a := rng.randf_range(-PI * 0.6, PI * 0.6)
		var z := rng.randf_range(-0.11, 0.11)
		var p := Vector3(sin(a) * 0.066, 0.19 + cos(a) * 0.066, z)
		var col := CREAM_LIGHT if rng.randf() < 0.5 else CREAM
		Geo.mesh(_bob, Geo.sphere(rng.randf_range(0.009, 0.015), 6), p, col,
				Vector3(rng.randf() * 40, rng.randf() * 90, 0), Vector3(1.0, 0.6, 1.4))

	# Neck and head. The head is big for the body, like his.
	_neck = Node3D.new()
	_neck.position = Vector3(0, 0.225, -0.105)
	_bob.add_child(_neck)
	Geo.mesh(_neck, Geo.capsule(0.036, 0.1), Vector3(0, 0.025, -0.01), CREAM, Vector3(-30, 0, 0))
	_head = Node3D.new()
	_head.position = Vector3(0, 0.072, -0.03)
	_neck.add_child(_head)
	Geo.mesh(_head, Geo.sphere(0.062, 16), Vector3.ZERO, CREAM, Vector3.ZERO, Vector3(1.0, 0.95, 1.0))
	Geo.mesh(_head, Geo.capsule(0.027, 0.07), Vector3(0, -0.02, -0.06), CREAM_LIGHT, Vector3(90, 0, 0))
	# Beard: soft whiskery mass under the muzzle.
	for i in 12:
		var p := Vector3(rng.randf_range(-0.022, 0.022), rng.randf_range(-0.048, -0.03),
				rng.randf_range(-0.085, -0.045))
		Geo.mesh(_head, Geo.sphere(rng.randf_range(0.008, 0.012), 6), p, CREAM_LIGHT)
	# Brows and eyes.
	for side in [-1.0, 1.0]:
		Geo.mesh(_head, Geo.sphere(0.011, 6), Vector3(side * 0.024, 0.025, -0.05), CREAM_LIGHT,
				Vector3.ZERO, Vector3(1.3, 0.6, 1.0))
		Geo.mesh(_head, Geo.sphere(0.0085, 8), Vector3(side * 0.024, 0.009, -0.054), EYE)
	Geo.mesh(_head, Geo.sphere(0.012, 8), Vector3(0, -0.008, -0.096), NOSE, Vector3.ZERO, Vector3(1.2, 0.9, 1.0))
	mouth = Node3D.new()
	mouth.position = Vector3(0, -0.045, -0.095)
	_head.add_child(mouth)

	# Ears: set high, folding forward so the tips hang down beside the eyes.
	for side in [-1.0, 1.0]:
		var ear := Node3D.new()
		ear.position = Vector3(side * 0.042, 0.044, -0.004)
		_head.add_child(ear)
		Geo.mesh(ear, Geo.sphere(1.0, 10), Vector3(0, 0, -0.034), BLONDE,
				Vector3.ZERO, Vector3(0.027, 0.008, 0.04))
		Geo.mesh(ear, Geo.sphere(1.0, 8), Vector3(0, -0.001, -0.062), BLONDE_DARK,
				Vector3.ZERO, Vector3(0.019, 0.007, 0.016))
		_ears.append(ear)

	# Legs: skinny. Hind legs carry a little angulation (set in animate()).
	for front in [true, false]:
		for side in [-1.0, 1.0]:
			var hip := Node3D.new()
			hip.position = Vector3(side * 0.04, 0.17, -0.085 if front else 0.085)
			_bob.add_child(hip)
			Geo.mesh(hip, Geo.cylinder(0.017, 0.013, 0.09, 8), Vector3(0, -0.045, 0), CREAM)
			var knee := Node3D.new()
			knee.position = Vector3(0, -0.09, 0)
			hip.add_child(knee)
			Geo.mesh(knee, Geo.cylinder(0.012, 0.011, 0.075, 8), Vector3(0, -0.037, 0), CREAM)
			Geo.mesh(knee, Geo.sphere(0.015, 8), Vector3(0, -0.074, -0.006), CREAM_LIGHT,
					Vector3.ZERO, Vector3(1.0, 0.6, 1.3))
			_legs.append({"hip": hip, "knee": knee, "front": front, "side": side})

	# Tail: upright, plumed, curving forward at the tip.
	var parent: Node3D = _bob
	var pos := Vector3(0, 0.232, 0.125)
	for i in 3:
		var seg := Node3D.new()
		seg.position = pos
		parent.add_child(seg)
		Geo.mesh(seg, Geo.capsule(0.012, 0.06), Vector3(0, 0.028, 0), CREAM)
		Geo.mesh(seg, Geo.sphere(0.016, 6), Vector3(0, 0.032, 0.01), CREAM_LIGHT,
				Vector3.ZERO, Vector3(0.8, 1.5, 0.9))
		_tail.append(seg)
		parent = seg
		pos = Vector3(0, 0.05, 0)
