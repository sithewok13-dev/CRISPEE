extends Node3D
class_name LivingRoom
## Territory 1. Grey-box of the real living room: orange walls, black couch,
## the air conditioner box, a hallway door that only Dad can open.

signal reaction(text)

var dad: Human
var cat: MeshInstance3D
var ac_box: StaticBody3D
var door: StaticBody3D
var exit_zone: Area3D
var water: Area3D
var spots := {}

const ORANGE := Color(0.85, 0.38, 0.17)
const FLOOR := Color(0.55, 0.47, 0.38)

func _box(pos: Vector3, size: Vector3, color: Color, body := true, parent: Node = null) -> Node3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = size
	mi.mesh = bm
	var mat := StandardMaterial3D.new(); mat.albedo_color = color
	mi.material_override = mat
	var p: Node = parent if parent else self
	if body:
		var sb := StaticBody3D.new(); sb.position = pos
		sb.collision_layer = 1; sb.collision_mask = 0
		var cs := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = size; cs.shape = bs
		sb.add_child(cs); sb.add_child(mi)
		p.add_child(sb)
		return sb
	mi.position = pos
	p.add_child(mi)
	return mi

func build() -> void:
	# Room: 7 m wide (x), 6 m deep (z). Back wall at z=-3, front wall (hallway door) at z=+3.
	_box(Vector3(0, -0.05, 0), Vector3(7, 0.1, 6), FLOOR)
	_box(Vector3(0, 1.3, -3.05), Vector3(7, 2.6, 0.1), ORANGE)
	_box(Vector3(-3.55, 1.3, 0), Vector3(0.1, 2.6, 6), ORANGE)
	_box(Vector3(3.55, 1.3, 0), Vector3(0.1, 2.6, 6), ORANGE)
	# Front wall with a door gap at x = -1.5 (0.9 wide)
	_box(Vector3(-2.725, 1.3, 3.05), Vector3(1.65, 2.6, 0.1), ORANGE)
	_box(Vector3(1.025, 1.3, 3.05), Vector3(5.05, 2.6, 0.1), ORANGE)
	_box(Vector3(-1.5, 2.3, 3.05), Vector3(0.9, 0.6, 0.1), ORANGE)
	door = _box(Vector3(-1.5, 1.0, 3.05), Vector3(0.9, 2.0, 0.08), Color(0.93, 0.9, 0.85))
	door.name = "Door"
	# Ceiling light
	var light := OmniLight3D.new(); light.position = Vector3(0, 2.4, 0); light.light_energy = 2.2; light.omni_range = 9
	light.light_color = Color(1, 0.93, 0.8); light.shadow_enabled = true
	add_child(light)
	var fill := DirectionalLight3D.new(); fill.rotation_degrees = Vector3(-55, 30, 0); fill.light_energy = 0.5
	add_child(fill)
	var env := WorldEnvironment.new(); var e := Environment.new()
	e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.1, 0.08, 0.07)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.5, 0.42, 0.36); e.ambient_light_energy = 0.9
	env.environment = e; add_child(env)
	# Couch against the back wall: seat, back, arms. Black leather.
	var black := Color(0.09, 0.09, 0.1)
	_box(Vector3(0, 0.225, -2.4), Vector3(2.2, 0.45, 0.9), black)
	_box(Vector3(0, 0.75, -2.8), Vector3(2.2, 0.75, 0.25), black)
	_box(Vector3(-1.2, 0.35, -2.4), Vector3(0.2, 0.7, 0.9), black)
	_box(Vector3(1.2, 0.35, -2.4), Vector3(0.2, 0.7, 0.9), black)
	# Cushion on the seat (the claim)
	_box(Vector3(0.5, 0.49, -2.35), Vector3(0.7, 0.08, 0.6), Color(0.14, 0.14, 0.16))
	# The air conditioner box, next to the couch. Hop: floor -> couch seat (0.45) -> box top (0.6).
	ac_box = _box(Vector3(1.75, 0.3, -2.3), Vector3(0.6, 0.6, 0.6), Color(0.16, 0.35, 0.62))
	ac_box.name = "ACBox"
	# Coffee table with Grandma's purse on it
	_box(Vector3(0, 0.2, -0.7), Vector3(1.0, 0.4, 0.5), Color(0.35, 0.22, 0.12))
	_box(Vector3(0.2, 0.47, -0.7), Vector3(0.26, 0.14, 0.16), Color(0.45, 0.12, 0.14))
	# Dad's slipper on the floor
	_box(Vector3(-2.0, 0.03, 0.6), Vector3(0.12, 0.06, 0.3), Color(0.4, 0.3, 0.2), false)
	# The cat's bed in the far left corner behind the couch arm; gap 0.3 m between arm and wall
	_box(Vector3(-3.15, 0.04, -2.6), Vector3(0.5, 0.08, 0.5), Color(0.6, 0.5, 0.6), false)
	cat = _box(Vector3(-3.15, 0.16, -2.6), Vector3(0.28, 0.16, 0.36), Color(0.45, 0.45, 0.48), false)
	# Thermostat on the right wall, 1.1 m up, reachable only from the box once Dad moves it
	_box(Vector3(3.47, 1.1, -1.2), Vector3(0.05, 0.12, 0.12), Color(0.95, 0.95, 0.95), false)
	# Water bowl
	_box(Vector3(2.8, 0.03, 2.2), Vector3(0.24, 0.06, 0.24), Color(0.3, 0.6, 0.85), false)
	water = Area3D.new(); water.position = Vector3(2.8, 0.1, 2.2); water.collision_layer = 0; water.collision_mask = 2
	var wc := CollisionShape3D.new(); var ws := SphereShape3D.new(); ws.radius = 0.35; wc.shape = ws; water.add_child(wc); add_child(water)
	# Exit beyond the door
	exit_zone = Area3D.new(); exit_zone.position = Vector3(-1.5, 0.3, 3.35); exit_zone.collision_layer = 0; exit_zone.collision_mask = 2
	var ec := CollisionShape3D.new(); var es := BoxShape3D.new(); es.size = Vector3(0.9, 0.6, 0.5); ec.shape = es; exit_zone.add_child(ec); add_child(exit_zone)
	_box(Vector3(-1.5, -0.05, 3.8), Vector3(1.2, 0.1, 1.5), Color(0.4, 0.35, 0.3))
	# Dad, standing by the thermostat
	dad = Human.new(); dad.name = "Dad"; dad.position = Vector3(2.6, 0, -0.6)
	add_child(dad)
	dad.arrived.connect(_on_dad_arrived)
	# Claims. key, label, reaction, position, size, world change
	_spot("slipper", "Dad's slipper", "Dad picks up the slipper, considers it, and puts it back. It is Crispee's now. Dad wears the other one.", Vector3(-2.0, 0.15, 0.6), Vector3(0.5, 0.3, 0.6))
	_spot("purse", "Grandma's purse", "Grandma moves her wallet to a bag Crispee has not met yet. The purse stays. It is Crispee's.", Vector3(0.2, 0.55, -0.7), Vector3(0.5, 0.3, 0.4))
	_spot("cushion", "The couch cushion", "The family will sit on the floor from now on. The cushion is Crispee's.", Vector3(0.5, 0.6, -2.35), Vector3(0.7, 0.3, 0.6))
	_spot("acbox", "The air conditioner box", "Dad moves the box under the thermostat so Crispee can reach it. He thinks it is a step. It is.", Vector3(1.75, 0.72, -2.3), Vector3(0.6, 0.3, 0.6), "box_moved")
	_spot("thermostat", "The thermostat", "The house is now set to 58 degrees. Dad opens the hallway door to let the heat in. The hallway is next.", Vector3(3.15, 0.95, -1.2), Vector3(0.6, 0.7, 0.7), "door_open")
	_spot("catbed", "The cat's bed", "The cat has seen everything. The cat says nothing.", Vector3(-3.15, 0.15, -2.6), Vector3(0.5, 0.3, 0.5))
	Game.world_changed.connect(_on_world_changed)

func _spot(key: String, label: String, react: String, pos: Vector3, size: Vector3, world_key := "") -> void:
	var s := ClaimSpot.make(key, label, react, pos, size, world_key)
	add_child(s)
	spots[key] = s
	Game.register_spot(s)

func _on_world_changed(key: String) -> void:
	match key:
		"box_moved":
			dad.say("Fine. FINE.")
			dad.walk_to(Vector3(2.35, 0, -2.3), "at_box")
		"door_open":
			dad.say("Why is it so cold.")
			dad.walk_to(Vector3(-1.5, 0, 2.3), "at_door")

func _on_dad_arrived(tag: String) -> void:
	match tag:
		"at_box":
			dad.carrying = ac_box
			ac_box.collision_layer = 0
			dad.walk_to(Vector3(2.95, 0, -0.55), "box_placed")
		"box_placed":
			dad.carrying = null
			ac_box.position = Vector3(2.95, 0.3, -1.2)
			ac_box.collision_layer = 1
			spots["acbox"].position = Vector3(2.95, 0.72, -1.2)
			spots["thermostat"].position = Vector3(3.15, 0.95, -1.2)
			dad.walk_to(Vector3(2.0, 0, 0.6), "")
		"at_door":
			var tw := create_tween()
			tw.tween_property(door, "position:x", -2.2, 0.8)
			tw.parallel().tween_property(door, "position:z", 3.5, 0.8)
			dad.walk_to(Vector3(0.5, 0, 1.5), "")
