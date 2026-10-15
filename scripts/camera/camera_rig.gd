class_name CameraRig
extends Node3D
## Close third-person camera, low and slightly above/behind a small dog.
## Player drags or sticks to orbit; when left alone while moving, it drifts
## back behind him. CameraZones override framing in tight spaces.

const DEFAULTS := {"distance": 1.2, "height": 0.34, "pitch": -12.0, "fov": 68.0}
const DRAG_SENSITIVITY := 0.006
const STICK_RATE := 2.6
const RECENTER_DELAY := 1.4
const RECENTER_RATE := 1.6
const PITCH_MIN := -55.0
const PITCH_MAX := 8.0

var target: Node3D
var yaw := 0.0
var pitch := deg_to_rad(DEFAULTS.pitch)

var camera: Camera3D
var _arm: SpringArm3D
var _params := DEFAULTS.duplicate()
var _zones: Array[Dictionary] = []
var _idle_input := 10.0
var _excluded := false


func _ready() -> void:
	top_level = true
	_arm = SpringArm3D.new()
	_arm.collision_mask = Geo.LAYER_WORLD
	var probe := SphereShape3D.new()
	probe.radius = 0.06
	_arm.shape = probe
	_arm.margin = 0.03
	add_child(_arm)
	camera = Camera3D.new()
	camera.near = 0.03
	camera.far = 60.0
	camera.current = true
	_arm.add_child(camera)


func get_yaw() -> float:
	return yaw


func snap_behind() -> void:
	if target:
		yaw = target.rotation.y
		global_position = target.global_position + Vector3.UP * float(_params.height)


func push_zone(zone: Dictionary) -> void:
	_zones.append(zone)


func pop_zone(zone: Dictionary) -> void:
	_zones.erase(zone)


func _physics_process(delta: float) -> void:
	if target == null:
		return
	if not _excluded and target is CollisionObject3D:
		_arm.add_excluded_object((target as CollisionObject3D).get_rid())
		_excluded = true

	# Desired framing: defaults, overridden by the most recent zone.
	var want: Dictionary = DEFAULTS.duplicate()
	if not _zones.is_empty():
		want.merge(_zones.back(), true)
	var k := 1.0 - exp(-4.0 * delta)
	for key in ["distance", "height", "fov"]:
		_params[key] = lerpf(_params[key], want[key], k)

	# Player input.
	var drag := InputRouter.consume_camera_drag()
	var rate := InputRouter.get_camera_rate()
	var turned := drag.length() > 0.5 or rate.length() > 0.1
	yaw -= drag.x * DRAG_SENSITIVITY + rate.x * STICK_RATE * delta
	pitch -= drag.y * DRAG_SENSITIVITY + rate.y * STICK_RATE * 0.6 * delta
	_idle_input = 0.0 if turned else _idle_input + delta

	var v := Vector3.ZERO
	if target is CharacterBody3D:
		v = (target as CharacterBody3D).velocity
	var hspeed := Vector2(v.x, v.z).length()
	var drifting := _idle_input > RECENTER_DELAY and hspeed > 0.4

	# Zones hold their pitch; otherwise pitch eases home only while drifting.
	if (not _zones.is_empty() and _idle_input > 0.3) or drifting:
		pitch = lerp_angle(pitch, deg_to_rad(want.pitch), 1.0 - exp(-2.0 * delta))
	pitch = clampf(pitch, deg_to_rad(PITCH_MIN), deg_to_rad(PITCH_MAX))

	# Boxed in (e.g. backed against the couch): rise and look down over it.
	if _arm.get_hit_length() < float(_params.distance) * 0.55 and _idle_input > 0.4:
		pitch = lerp_angle(pitch, deg_to_rad(-40.0), 1.0 - exp(-3.0 * delta))

	# Drift back behind him while he moves and the player isn't steering.
	if drifting:
		var behind := atan2(-v.x, -v.z)
		var strength := clampf(hspeed / 2.0, 0.2, 1.0)
		yaw = lerp_angle(yaw, behind, 1.0 - exp(-RECENTER_RATE * strength * delta))

	# Follow: firm horizontally, softer vertically so hops don't jolt.
	var goal: Vector3 = target.global_position + Vector3.UP * float(_params.height)
	var p := global_position
	p.x = lerpf(p.x, goal.x, 1.0 - exp(-14.0 * delta))
	p.z = lerpf(p.z, goal.z, 1.0 - exp(-14.0 * delta))
	p.y = lerpf(p.y, goal.y, 1.0 - exp(-6.0 * delta))
	global_position = p
	rotation = Vector3(pitch, yaw, 0.0)
	_arm.spring_length = _params.distance
	camera.fov = _params.fov
