extends Node3D
## Semi-automatic third-person camera. Follows behind and above the dog,
## turns toward the dog's heading, and takes a swipe nudge from the right half.

@export var distance := 2.3
@export var height := 1.15
@export var look_height := 0.25
@export var follow_speed := 4.0
@export var yaw_follow := 2.2

var target: Node3D
var yaw := 0.0
var _nudge := 0.0
var arm: SpringArm3D
var cam: Camera3D

func _ready() -> void:
	arm = SpringArm3D.new()
	arm.spring_length = distance
	arm.margin = 0.05
	arm.collision_mask = 1
	add_child(arm)
	cam = Camera3D.new()
	cam.fov = 62
	cam.near = 0.03
	arm.add_child(cam)
	cam.current = true

func nudge(amount: float) -> void:
	_nudge += amount

func _physics_process(delta: float) -> void:
	if not target:
		return
	var tpos: Vector3 = target.global_position
	global_position = global_position.lerp(tpos + Vector3(0, look_height, 0), 1.0 - exp(-follow_speed * delta))
	# Follow the dog's heading when it moves, otherwise hold.
	var v: Vector3 = target.velocity if "velocity" in target else Vector3.ZERO
	v.y = 0
	if v.length() > 0.4:
		var want := atan2(-v.x, -v.z)
		yaw = lerp_angle(yaw, want, 1.0 - exp(-yaw_follow * delta))
	yaw += _nudge
	_nudge = 0.0
	rotation.y = yaw
	var pitch := -atan2(height, distance)
	var hit := arm.get_hit_length()
	if hit < distance * 0.6:
		# Something is right behind the dog: look down from above instead of clipping.
		var k: float = clamp(1.0 - hit / (distance * 0.6), 0.0, 1.0)
		pitch = lerp(pitch, -1.25, k)
	arm.rotation.x = lerp_angle(arm.rotation.x, pitch, 1.0 - exp(-6.0 * delta))
	arm.position = Vector3.ZERO
