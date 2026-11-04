extends CharacterBody3D
class_name Human
## A household human. Walks to points, reacts to barks, carries things.

signal arrived(tag)

@export var walk_speed := 1.1
var human_name := "Dad"
var _goal := Vector3.ZERO
var _goal_tag := ""
var _moving := false
var carrying: Node3D
var pivot: Node3D
var bubble: Label3D
var _bubble_t := 0.0
var sense: Area3D

func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new(); cap.radius = 0.22; cap.height = 1.75
	cs.shape = cap; cs.position.y = 0.875
	add_child(cs)
	pivot = Node3D.new(); add_child(pivot)
	var shirt := StandardMaterial3D.new(); shirt.albedo_color = Color(0.12, 0.12, 0.13)
	var skin := StandardMaterial3D.new(); skin.albedo_color = Color(0.85, 0.68, 0.58)
	var jeans := StandardMaterial3D.new(); jeans.albedo_color = Color(0.25, 0.3, 0.42)
	var legs := MeshInstance3D.new(); var lm := BoxMesh.new(); lm.size = Vector3(0.36, 0.85, 0.26)
	legs.mesh = lm; legs.material_override = jeans; legs.position.y = 0.425; pivot.add_child(legs)
	var torso := MeshInstance3D.new(); var tm := BoxMesh.new(); tm.size = Vector3(0.46, 0.62, 0.28)
	torso.mesh = tm; torso.material_override = shirt; torso.position.y = 1.16; pivot.add_child(torso)
	var head := MeshInstance3D.new(); var hm := SphereMesh.new(); hm.radius = 0.13; hm.height = 0.26
	head.mesh = hm; head.material_override = skin; head.position.y = 1.62; pivot.add_child(head)
	bubble = Label3D.new()
	bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bubble.font_size = 48; bubble.pixel_size = 0.0012
	bubble.position.y = 1.95
	bubble.modulate = Color(1, 1, 1)
	bubble.outline_size = 8
	bubble.visible = false
	add_child(bubble)
	sense = Area3D.new()
	sense.collision_layer = 0; sense.collision_mask = 2
	var ss := CollisionShape3D.new(); var sph := SphereShape3D.new(); sph.radius = 1.1
	ss.shape = sph; ss.position.y = 0.4
	sense.add_child(ss); add_child(sense)
	sense.body_entered.connect(func(b): if b is Crispee: b.near_human = self)
	sense.body_exited.connect(func(b): if b is Crispee and b.near_human == self: b.near_human = null)

func say(text: String, seconds := 3.0) -> void:
	bubble.text = text
	bubble.visible = true
	_bubble_t = seconds

func walk_to(p: Vector3, tag := "") -> void:
	_goal = p; _goal_tag = tag; _moving = true

func on_bark(dog: Node3D) -> void:
	say("...what.")
	var d := dog.global_position - global_position; d.y = 0
	if d.length() > 0.01:
		pivot.rotation.y = atan2(-d.x, -d.z)

func _physics_process(delta: float) -> void:
	if _bubble_t > 0.0:
		_bubble_t -= delta
		if _bubble_t <= 0.0: bubble.visible = false
	if _moving:
		var d := _goal - global_position; d.y = 0
		if d.length() < 0.15:
			_moving = false
			velocity = Vector3.ZERO
			var tag := _goal_tag; _goal_tag = ""
			arrived.emit(tag)
		else:
			var dir := d.normalized()
			velocity.x = dir.x * walk_speed; velocity.z = dir.z * walk_speed
			pivot.rotation.y = atan2(-dir.x, -dir.z)
	else:
		velocity.x = move_toward(velocity.x, 0, 6 * delta); velocity.z = move_toward(velocity.z, 0, 6 * delta)
	if not is_on_floor(): velocity.y -= 9.8 * delta
	else: velocity.y = 0
	move_and_slide()
	if carrying:
		carrying.global_position = global_position + Vector3(0, 0.75, 0) + pivot.global_transform.basis.z * -0.45
