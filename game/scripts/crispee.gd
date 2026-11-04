extends CharacterBody3D
class_name Crispee
## The dog. Four verbs: move, jump, pee, act. Powers live in main.

signal prompt_changed(text)

@export var speed := 2.2
@export var accel := 14.0
@export var gravity := 14.7
@export var jump_height := 0.55
@export var coyote_time := 0.12
@export var jump_buffer := 0.1

var input_dir := Vector2.ZERO       # set by touch stick or keys
var want_jump := false
var _coyote := 0.0
var _buffer := 0.0
var _facing := 0.0
var body_pivot: Node3D
var spots_in: Array = []
var current_spot: ClaimSpot:
	get:
		for sp in spots_in:
			if not sp.is_owned():
				return sp
		return spots_in[0] if spots_in.size() > 0 else null
var near_human: Node3D
var near_water := false
var is_peeing := false
var _pee_t := 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new(); cap.radius = 0.11; cap.height = 0.3
	cs.shape = cap
	cs.rotation_degrees.x = 90
	cs.position.y = 0.17
	add_child(cs)
	body_pivot = Node3D.new(); body_pivot.name = "Pivot"
	add_child(body_pivot)
	_build_placeholder()

func _build_placeholder() -> void:
	# Grey-box Crispee: cream capsule body, box head, red horns and cape.
	var cream := StandardMaterial3D.new(); cream.albedo_color = Color(0.91, 0.84, 0.70)
	var red := StandardMaterial3D.new(); red.albedo_color = Color(0.91, 0.25, 0.16)
	var dark := StandardMaterial3D.new(); dark.albedo_color = Color(0.15, 0.13, 0.12)
	var body := MeshInstance3D.new()
	var cm := CapsuleMesh.new(); cm.radius = 0.1; cm.height = 0.34
	body.mesh = cm; body.material_override = cream
	body.rotation_degrees.x = 90; body.position = Vector3(0, 0.17, 0)
	body_pivot.add_child(body)
	var head := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = Vector3(0.14, 0.13, 0.15)
	head.mesh = bm; head.material_override = cream
	head.position = Vector3(0, 0.27, -0.2)
	body_pivot.add_child(head)
	var nose := MeshInstance3D.new()
	var nm := BoxMesh.new(); nm.size = Vector3(0.05, 0.04, 0.03)
	nose.mesh = nm; nose.material_override = dark
	nose.position = Vector3(0, 0.25, -0.29)
	body_pivot.add_child(nose)
	for sx in [-1.0, 1.0]:
		var horn := MeshInstance3D.new()
		var hm := CylinderMesh.new(); hm.top_radius = 0.0; hm.bottom_radius = 0.025; hm.height = 0.09
		horn.mesh = hm; horn.material_override = red
		horn.position = Vector3(0.05 * sx, 0.37, -0.19)
		horn.rotation_degrees.z = -20 * sx
		body_pivot.add_child(horn)
		var eye := MeshInstance3D.new()
		var em := SphereMesh.new(); em.radius = 0.02; em.height = 0.04
		eye.mesh = em; eye.material_override = dark
		eye.position = Vector3(0.045 * sx, 0.3, -0.275)
		body_pivot.add_child(eye)
	var cape := MeshInstance3D.new()
	var capm := BoxMesh.new(); capm.size = Vector3(0.22, 0.01, 0.3)
	cape.mesh = capm; cape.material_override = red
	cape.position = Vector3(0, 0.275, 0.0)
	body_pivot.add_child(cape)
	var tail := MeshInstance3D.new()
	var tm := CylinderMesh.new(); tm.top_radius = 0.01; tm.bottom_radius = 0.02; tm.height = 0.14
	tail.mesh = tm; tail.material_override = cream
	tail.position = Vector3(0, 0.3, 0.17); tail.rotation_degrees.x = -25
	body_pivot.add_child(tail)
	for lx in [-0.06, 0.06]:
		for lz in [-0.1, 0.1]:
			var leg := MeshInstance3D.new()
			var lm := CylinderMesh.new(); lm.top_radius = 0.02; lm.bottom_radius = 0.02; lm.height = 0.12
			leg.mesh = lm; leg.material_override = cream
			leg.position = Vector3(lx, 0.06, lz)
			body_pivot.add_child(leg)

func jump_velocity() -> float:
	return sqrt(2.0 * gravity * jump_height)

func _physics_process(delta: float) -> void:
	if is_peeing:
		_pee_t -= delta
		velocity.x = 0; velocity.z = 0
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		if _pee_t <= 0.0:
			is_peeing = false
			body_pivot.rotation.z = 0.0
		return
	var dir := Vector2.ZERO
	var kb := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	dir = kb if kb.length() > input_dir.length() else input_dir
	if Input.is_action_just_pressed("jump"):
		want_jump = true
	# camera-relative movement
	var cam := get_viewport().get_camera_3d()
	var fwd := Vector3.FORWARD
	var right := Vector3.RIGHT
	if cam:
		fwd = -cam.global_transform.basis.z; fwd.y = 0; fwd = fwd.normalized()
		right = cam.global_transform.basis.x; right.y = 0; right = right.normalized()
	var wish := (right * dir.x + fwd * -dir.y)
	if wish.length() > 1.0:
		wish = wish.normalized()
	var target := wish * speed
	velocity.x = move_toward(velocity.x, target.x, accel * delta)
	velocity.z = move_toward(velocity.z, target.z, accel * delta)
	if is_on_floor():
		_coyote = coyote_time
		if velocity.y < 0: velocity.y = 0
	else:
		_coyote -= delta
		velocity.y -= gravity * delta
	if want_jump:
		_buffer = jump_buffer
		want_jump = false
	else:
		_buffer -= delta
	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = jump_velocity()
		_buffer = 0.0; _coyote = 0.0
	move_and_slide()
	if wish.length() > 0.05:
		_facing = lerp_angle(_facing, atan2(-wish.x, -wish.z), 12.0 * delta)
	body_pivot.rotation.y = _facing
	_update_prompt()

func _update_prompt() -> void:
	var text := ""
	if current_spot and not current_spot.is_owned():
		text = "Claim: " + current_spot.label if Game.can_mark() else "Empty. Find water."
	elif near_water and Game.marks < Game.max_marks:
		text = "Act: drink"
	elif near_human:
		text = "Act: bark at " + near_human.name
	prompt_changed.emit(text)

func try_pee() -> bool:
	if is_peeing or current_spot == null or current_spot.is_owned():
		return false
	if not Game.can_mark():
		return false
	if Game.mark(current_spot):
		is_peeing = true
		_pee_t = 1.1
		body_pivot.rotation.z = 0.35
		current_spot.show_puddle()
		return true
	return false

func try_act() -> String:
	if near_water and Game.marks < Game.max_marks:
		Game.refill()
		return "drink"
	if near_human:
		if near_human.has_method("on_bark"):
			near_human.on_bark(self)
		return "bark"
	return ""
