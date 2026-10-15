class_name Human
extends AnimatableBody3D
## A person who interprets Crispee. Behaviour is a queue of small steps
## (walk, say, wait, face, sit, call) so puzzles can script reactions out of
## reusable pieces instead of bespoke state machines.
##
## Receiving items is delegated: the puzzle decides what this human accepts
## and what happens next.

const WALK_SPEED := 1.15
const SPEAKER := "Human"

var seat_position := Vector3.ZERO
var seat_yaw := 0.0
var seated := false
## func(item: Interactable) -> bool
var accept_filter: Callable
## func(item: Interactable) -> void
var on_item_received: Callable

var hands: Node3D

var _tasks: Array[Dictionary] = []
var _current: Dictionary = {}
var _wait := 0.0
var _pelvis: Node3D
var _thighs: Array[Node3D] = []
var _shins: Array[Node3D] = []
var _arms: Array[Node3D] = []
var _walk_phase := 0.0
var _holding: Node3D = null


func _ready() -> void:
	add_to_group("receiver")
	# Moved by script each physics frame; physics sync would fight that.
	sync_to_physics = false
	collision_layer = Geo.LAYER_HUMAN
	collision_mask = 0
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.2
	cap.height = 1.7
	shape.shape = cap
	shape.position.y = 0.85
	add_child(shape)
	_build()


# --- Task API ------------------------------------------------------------------

func busy() -> bool:
	return not _current.is_empty() or not _tasks.is_empty()


func run(steps: Array) -> void:
	for s in steps:
		_tasks.append(s)


func interrupt() -> void:
	_tasks.clear()
	_current = {}


static func walk(to: Vector3) -> Dictionary:
	return {"walk": to}


static func say(text: String, duration: float = 2.6) -> Dictionary:
	return {"say": text, "duration": duration}


static func wait(seconds: float) -> Dictionary:
	return {"wait": seconds}


static func face(point: Vector3) -> Dictionary:
	return {"face": point}


static func sit() -> Dictionary:
	return {"sit": true}


static func call_fn(fn: Callable) -> Dictionary:
	return {"fn": fn}


func sit_now() -> void:
	global_position = seat_position
	rotation.y = seat_yaw
	seated = true


# --- Receiver interface (used by Crispee) ---------------------------------------

func accepts(item: Node) -> bool:
	return not busy() and accept_filter.is_valid() and accept_filter.call(item)


func receive_item(item: Node) -> void:
	hold(item)
	if on_item_received.is_valid():
		on_item_received.call(item)


func hold(item: Node3D) -> void:
	_holding = item
	item.reparent(hands, false)
	item.position = Vector3.ZERO
	item.rotation = Vector3.ZERO


func release(item: Node3D, parent: Node3D, at: Vector3) -> void:
	if _holding == item:
		_holding = null
	item.reparent(parent, false)
	item.global_position = at
	item.rotation = Vector3.ZERO


# --- Update ----------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	var walking := false
	if _current.is_empty() and not _tasks.is_empty():
		_current = _tasks.pop_front()
		_wait = 0.0
		if _current.has("say"):
			GameEvents.say(_current["say"], SPEAKER, _current["duration"])
		if _current.has("fn"):
			(_current["fn"] as Callable).call()
			_current = {}
		elif _current.has("sit"):
			sit_now()
			_current = {}
	if _current.has("walk"):
		seated = false
		var to: Vector3 = _current["walk"]
		var d := to - global_position
		d.y = 0.0
		if d.length() < 0.04:
			_current = {}
		else:
			walking = true
			var step := minf(WALK_SPEED * delta, d.length())
			global_position += d.normalized() * step
			rotation.y = lerp_angle(rotation.y, atan2(-d.x, -d.z), 1.0 - exp(-10.0 * delta))
	elif _current.has("face"):
		var d: Vector3 = _current["face"] - global_position
		var yaw := atan2(-d.x, -d.z)
		rotation.y = lerp_angle(rotation.y, yaw, 1.0 - exp(-8.0 * delta))
		if absf(angle_difference(rotation.y, yaw)) < 0.05:
			_current = {}
	elif _current.has("wait"):
		_wait += delta
		if _wait >= float(_current["wait"]):
			_current = {}
	elif _current.has("say"):
		_wait += delta
		if _wait >= 0.3:
			_current = {}
	_animate(delta, walking)


func _animate(delta: float, walking: bool) -> void:
	if walking:
		_walk_phase += delta * 7.0
	var k := 1.0 - exp(-12.0 * delta)
	var pelvis_y := 0.47 if seated else 0.86
	_pelvis.position.y = lerpf(_pelvis.position.y, pelvis_y, k)
	for i in 2:
		var side := 1.0 if i == 0 else -1.0
		var swing := sin(_walk_phase) * 0.45 * side if walking else 0.0
		var thigh_x := deg_to_rad(88.0) if seated else swing
		var shin_x := deg_to_rad(-88.0) if seated else (-maxf(0.0, -sin(_walk_phase) * side) * 0.6 if walking else 0.0)
		_thighs[i].rotation.x = lerp_angle(_thighs[i].rotation.x, thigh_x, k)
		_shins[i].rotation.x = lerp_angle(_shins[i].rotation.x, shin_x, k)
		var arm_x := deg_to_rad(70.0) if _holding else (-swing * 0.8 if walking else 0.0)
		if seated and not _holding:
			arm_x = deg_to_rad(45.0)
		_arms[i].rotation.x = lerp_angle(_arms[i].rotation.x, arm_x, k)


func _build() -> void:
	var skin := Color(0.80, 0.62, 0.50)
	var shirt := Color(0.33, 0.52, 0.55)
	var trousers := Color(0.22, 0.24, 0.30)
	var hair := Color(0.20, 0.14, 0.10)
	_pelvis = Node3D.new()
	_pelvis.position.y = 0.86
	add_child(_pelvis)
	Geo.mesh(_pelvis, Geo.capsule(0.17, 0.42), Vector3(0, 0.05, 0), trousers, Vector3(0, 0, 90),
			Vector3(1.0, 1.0, 0.7))
	for side in [-1.0, 1.0]:
		var thigh := Node3D.new()
		thigh.position = Vector3(side * 0.1, 0.0, 0.0)
		_pelvis.add_child(thigh)
		Geo.mesh(thigh, Geo.capsule(0.075, 0.46), Vector3(0, -0.21, 0), trousers)
		var shin := Node3D.new()
		shin.position = Vector3(0, -0.42, 0)
		thigh.add_child(shin)
		Geo.mesh(shin, Geo.capsule(0.06, 0.44), Vector3(0, -0.2, 0), trousers)
		Geo.mesh(shin, Geo.capsule(0.05, 0.22), Vector3(0, -0.41, -0.05), Color(0.9, 0.9, 0.88),
				Vector3(90, 0, 0))
		_thighs.append(thigh)
		_shins.append(shin)
	var chest := Node3D.new()
	chest.position.y = 0.08
	_pelvis.add_child(chest)
	Geo.mesh(chest, Geo.capsule(0.19, 0.62), Vector3(0, 0.28, 0), shirt, Vector3.ZERO, Vector3(1.0, 1.0, 0.65))
	Geo.mesh(chest, Geo.sphere(0.11), Vector3(0, 0.72, 0), skin)
	Geo.mesh(chest, Geo.sphere(0.115), Vector3(0, 0.76, 0.02), hair, Vector3.ZERO, Vector3(1.0, 0.8, 1.0))
	Geo.mesh(chest, Geo.sphere(0.02), Vector3(0, 0.71, -0.11), skin)
	for side in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.position = Vector3(side * 0.24, 0.52, 0)
		chest.add_child(arm)
		Geo.mesh(arm, Geo.capsule(0.05, 0.6), Vector3(0, -0.27, 0), shirt)
		Geo.mesh(arm, Geo.sphere(0.045), Vector3(0, -0.58, 0), skin)
		_arms.append(arm)
	hands = Node3D.new()
	hands.position = Vector3(0, 0.12, -0.42)
	chest.add_child(hands)
