class_name LivingRoom
extends Node3D
## GREYBOX living room for the first playable ("The Delivery"). Layout is
## loosely based on the reference video: black couch with a donut bed and
## pet stairs at one end. Everything here is placeholder geometry sized in
## real metres, so the dog-eye scale is honest.
##
## Exposes the pieces the puzzle needs; holds no puzzle logic itself.

const WOOD := Color(0.56, 0.42, 0.3)
const WALL := Color(0.86, 0.66, 0.5)  # the warm orange-peach walls
const COUCH := Color(0.11, 0.10, 0.10)
const FABRIC_GREY := Color(0.62, 0.62, 0.63)
const CARDBOARD := Color(0.74, 0.57, 0.36)
const DARK_WOOD := Color(0.24, 0.17, 0.13)

const SPAWN := Vector3(-2.05, 0.47, 2.0)
const DOOR_INSIDE := Vector3(1.8, 0.0, -1.85)
const HUMAN_SEAT := Vector3(2.0, 0.0, 0.6)
const BOX_START := Vector3(0.9, 0.0, -2.05)
const BOX_SHELF_SPOT := Vector3(-2.31, 0.0, -1.3)
const BOX_HUMAN_STAND := Vector3(0.9, 0.0, -1.5)
const SHELF_HUMAN_STAND := Vector3(-1.72, 0.0, -1.3)
const SAUSAGE := Vector3(1.8, 0.0, -4.0)
const SCENT_SOURCE := Vector3(1.8, 0.05, -2.45)
const DESK_TOP := Vector3(2.75, 0.77, 0.25)

var human: Human
var box_root: Node3D
var box_mark: Interactable
var box_label: Label3D
var door_hinge: Node3D
var leash: Interactable
var sock: Interactable
var toy: Interactable
var slippers: Interactable
var slippers_label: Label3D
var end_area: Area3D


func _ready() -> void:
	_build_shell()
	_build_furniture()
	_build_props()
	_build_porch()
	_build_lighting()
	human = Human.new()
	human.name = "Human"
	human.seat_position = HUMAN_SEAT
	human.seat_yaw = -PI * 0.5
	add_child(human)
	human.sit_now()


func add_camera_zones(rig: CameraRig) -> void:
	# On the couch: the back is right behind him, so look down from above it.
	CameraZone.create(self, rig, Vector3(2.0, 0.6, 0.8), Vector3(-1.6, 0.75, 2.0),
			{"distance": 1.1, "height": 0.4, "pitch": -42.0, "fov": 70.0})
	# Under the coffee table: low, close, nearly level.
	CameraZone.create(self, rig, Vector3(1.3, 0.36, 0.7), Vector3(-0.4, 0.18, 0.3),
			{"distance": 0.62, "height": 0.16, "pitch": -3.0, "fov": 76.0})
	# Doorway and porch: pull in so the frame and walls don't swallow the view.
	CameraZone.create(self, rig, Vector3(1.4, 1.0, 2.2), Vector3(1.8, 0.5, -3.6),
			{"distance": 0.95, "height": 0.36, "pitch": -14.0, "fov": 70.0})


func set_door_open(open: bool, animate: bool = true) -> void:
	var target := deg_to_rad(-100.0) if open else 0.0
	if animate:
		create_tween().tween_property(door_hinge, "rotation:y", target, 1.1) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		door_hinge.rotation.y = target


# --- Construction ---------------------------------------------------------------

func _build_shell() -> void:
	Geo.box(self, "Floor", Vector3(6.2, 0.1, 5.2), Vector3(0, -0.05, 0), WOOD)
	var rug := Geo.box(self, "Rug", Vector3(2.4, 0.006, 1.8), Vector3(-0.4, 0.003, 0.3),
			Color(0.55, 0.53, 0.48), "", false) as GeometryInstance3D
	rug.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Geo.box(self, "WallSouth", Vector3(6.2, 2.6, 0.1), Vector3(0, 1.3, 2.55), WALL, "the wall")
	Geo.box(self, "WallWest", Vector3(0.1, 2.6, 5.2), Vector3(-3.05, 1.3, 0), WALL, "the wall")
	Geo.box(self, "WallEast", Vector3(0.1, 2.6, 5.2), Vector3(3.05, 1.3, 0), WALL, "the wall")
	Geo.box(self, "WallNorthA", Vector3(4.45, 2.6, 0.1), Vector3(-0.875, 1.3, -2.55), WALL, "the wall")
	Geo.box(self, "WallNorthB", Vector3(0.85, 2.6, 0.1), Vector3(2.675, 1.3, -2.55), WALL, "the wall")
	Geo.box(self, "DoorHeader", Vector3(0.9, 0.5, 0.1), Vector3(1.8, 2.35, -2.55), WALL)
	var ceiling := Geo.box(self, "Ceiling", Vector3(6.2, 0.1, 5.2), Vector3(0, 2.65, 0),
			Color(0.96, 0.93, 0.88), "", false) as GeometryInstance3D
	ceiling.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Skirting boards help read the floor/wall edge at dog height.
	for z in [2.49, -2.49]:
		Geo.box(self, "Skirting", Vector3(6.0, 0.08, 0.02), Vector3(0, 0.04, z), Color(0.95, 0.93, 0.9), "", false)

	# Front door, hinged on its west edge, swings into the room.
	door_hinge = Node3D.new()
	door_hinge.name = "DoorHinge"
	door_hinge.position = Vector3(1.35, 0, -2.55)
	add_child(door_hinge)
	Geo.box(door_hinge, "Door", Vector3(0.9, 2.08, 0.05), Vector3(0.45, 1.04, 0), Color(0.88, 0.86, 0.82), "the door")
	Geo.mesh(door_hinge, Geo.sphere(0.035), Vector3(0.8, 1.0, 0.05), Color(0.75, 0.62, 0.3))
	# A west window, cosmetic, for warm light and a sense of outside.
	var win := Geo.box(self, "Window", Vector3(0.02, 1.0, 1.3), Vector3(-2.99, 1.45, -1.3),
			Color(1.0, 0.95, 0.8), "", false) as GeometryInstance3D
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(1.0, 0.95, 0.82)
	wm.emission_enabled = true
	wm.emission = Color(1.0, 0.9, 0.7)
	wm.emission_energy_multiplier = 1.4
	win.material_override = wm


func _build_furniture() -> void:
	# Couch along the south wall. Seat 0.45 m: too high to hop, hence the stairs.
	Geo.box(self, "CouchSeat", Vector3(2.2, 0.45, 0.9), Vector3(-1.6, 0.225, 2.05), COUCH, "the couch")
	Geo.box(self, "CouchBack", Vector3(2.2, 0.48, 0.22), Vector3(-1.6, 0.69, 2.39), COUCH, "the couch")
	Geo.box(self, "CouchArmW", Vector3(0.2, 0.2, 0.9), Vector3(-2.6, 0.55, 2.05), COUCH, "the couch")
	Geo.box(self, "CouchArmE", Vector3(0.2, 0.2, 0.9), Vector3(-0.6, 0.55, 2.05), COUCH, "the couch")
	# Donut bed on the couch: his throne.
	var torus := TorusMesh.new()
	torus.inner_radius = 0.13
	torus.outer_radius = 0.25
	Geo.mesh(self, torus, Vector3(-2.05, 0.5, 2.0), Color(0.82, 0.82, 0.84))
	Geo.mesh(self, Geo.cylinder(0.15, 0.15, 0.03), Vector3(-2.05, 0.465, 2.0), Color(0.86, 0.86, 0.88))
	# Pet stairs: two 0.15 m steps he can walk up.
	Geo.box(self, "StairTop", Vector3(0.42, 0.3, 0.3), Vector3(-1.05, 0.15, 1.45), FABRIC_GREY, "the pet stairs")
	Geo.box(self, "StairLow", Vector3(0.42, 0.15, 0.3), Vector3(-1.05, 0.075, 1.15), FABRIC_GREY, "the pet stairs")

	# Coffee table: he fits underneath; the camera needs help there.
	Geo.box(self, "TableTop", Vector3(1.2, 0.04, 0.6), Vector3(-0.4, 0.4, 0.3), DARK_WOOD)
	for x in [-0.95, 0.15]:
		for z in [0.05, 0.55]:
			Geo.box(self, "TableLeg", Vector3(0.04, 0.38, 0.04), Vector3(x, 0.19, z), DARK_WOOD, "the coffee table")

	# The human's desk and chair on the east wall.
	Geo.box(self, "DeskTop", Vector3(0.6, 0.04, 1.2), Vector3(2.7, 0.74, 0.6), DARK_WOOD)
	for x in [2.44, 2.96]:
		for z in [0.04, 1.16]:
			Geo.box(self, "DeskLeg", Vector3(0.04, 0.72, 0.04), Vector3(x, 0.36, z), DARK_WOOD, "the desk")
	Geo.box(self, "Laptop", Vector3(0.3, 0.02, 0.22), Vector3(2.72, 0.77, 0.6), Color(0.2, 0.2, 0.22), "", false)
	Geo.box(self, "ChairSeat", Vector3(0.44, 0.05, 0.44), Vector3(2.0, 0.45, 0.6), Color(0.3, 0.3, 0.32))
	Geo.box(self, "ChairBack", Vector3(0.05, 0.45, 0.44), Vector3(1.8, 0.7, 0.6), Color(0.3, 0.3, 0.32))
	for x in [1.82, 2.18]:
		for z in [0.42, 0.78]:
			Geo.box(self, "ChairLeg", Vector3(0.03, 0.43, 0.03), Vector3(x, 0.215, z), Color(0.3, 0.3, 0.32), "the chair")

	# Low bookshelf under the window. 0.5 m: reachable only from something 0.25 m tall.
	Geo.box(self, "Bookshelf", Vector3(0.4, 0.5, 1.0), Vector3(-2.75, 0.25, -1.3), WOOD, "the bookshelf")
	var book_colors := [Color(0.5, 0.2, 0.2), Color(0.2, 0.35, 0.5), Color(0.6, 0.55, 0.3)]
	for i in 3:
		Geo.box(self, "Book", Vector3(0.28, 0.24, 0.05), Vector3(-2.78, 0.62, -1.74 + i * 0.06), book_colors[i])

	# Plant in the corner. Very claimable.
	Geo.box(self, "PlantPot", Vector3(0.32, 0.36, 0.32), Vector3(-2.6, 0.18, -2.15), Color(0.72, 0.4, 0.28), "the plant")
	for i in 5:
		var a := i * TAU / 5.0
		Geo.mesh(self, Geo.sphere(0.18, 8), Vector3(-2.6 + cos(a) * 0.12, 0.62 + (i % 2) * 0.15, -2.15 + sin(a) * 0.12),
				Color(0.3, 0.5, 0.28))
	# Floor lamp by the couch.
	Geo.box(self, "LampPole", Vector3(0.04, 1.5, 0.04), Vector3(-0.15, 0.75, 2.3), Color(0.2, 0.2, 0.2), "the lamp")
	Geo.mesh(self, Geo.cylinder(0.12, 0.2, 0.25), Vector3(-0.15, 1.55, 2.3), Color(1.0, 0.92, 0.75))


func _build_props() -> void:
	# The delivery box: unclaimed, therefore an affront.
	box_root = Node3D.new()
	box_root.name = "DeliveryBox"
	box_root.position = BOX_START
	add_child(box_root)
	Geo.box(box_root, "Box", Vector3(0.45, 0.25, 0.35), Vector3(0, 0.125, 0), CARDBOARD, "the box")
	Geo.box(box_root, "Tape", Vector3(0.46, 0.005, 0.06), Vector3(0, 0.252, 0), Color(0.8, 0.7, 0.5), "", false)
	box_label = Geo.label(box_root, "CRISPEE'S", Vector3(0, 0.13, 0.177), 64, Color(0.08, 0.08, 0.1))
	box_label.visible = false
	box_mark = _interactable(box_root, "box", "the delivery box", true, false, 0.5)

	# Leash on top of the bookshelf.
	leash = _item("leash", "the leash", Vector3(-2.75, 0.5, -1.12))
	Geo.mesh(leash, Geo.capsule(0.012, 0.3), Vector3(0, 0.012, 0), Color(0.55, 0.12, 0.12), Vector3(90, 0, 0))
	var loop := TorusMesh.new()
	loop.inner_radius = 0.04
	loop.outer_radius = 0.055
	Geo.mesh(leash, loop, Vector3(0, 0.01, -0.17), Color(0.55, 0.12, 0.12))
	Geo.mesh(leash, Geo.sphere(0.018), Vector3(0, 0.015, 0.15), Color(0.7, 0.7, 0.72))

	# Optional: a sock under the coffee table.
	sock = _item("sock", "a sock", Vector3(-0.15, 0.0, 0.22))
	Geo.mesh(sock, Geo.capsule(0.03, 0.16), Vector3(0, 0.03, 0), Color(0.9, 0.9, 0.95), Vector3(90, 0, 0))

	# Optional: a squeaky toy by the couch.
	toy = _item("toy", "the squeaky toy", Vector3(-1.7, 0.0, 1.25))
	toy.set_meta("squeaks", true)
	Geo.mesh(toy, Geo.sphere(0.04), Vector3(0, 0.04, 0), Color(0.95, 0.45, 0.2))

	# Optional special claim: the human's slippers.
	var sl_root := Node3D.new()
	sl_root.name = "Slippers"
	sl_root.position = Vector3(0.7, 0.0, 1.35)
	add_child(sl_root)
	for x in [-0.07, 0.07]:
		Geo.mesh(sl_root, Geo.capsule(0.045, 0.24), Vector3(x, 0.03, 0), Color(0.45, 0.3, 0.45),
				Vector3(90, 0, 0), Vector3(1.0, 1.0, 0.55))
	slippers_label = Geo.label(sl_root, "CRISPEE'S", Vector3(0, 0.09, 0), 28, Color(0.1, 0.1, 0.1))
	slippers_label.rotation_degrees = Vector3(-90, 0, 0)
	slippers_label.visible = false
	slippers = _interactable(sl_root, "slippers", "the slippers", true, false, 0.45)


func _build_porch() -> void:
	Geo.box(self, "PorchFloor", Vector3(1.7, 0.1, 2.1), Vector3(1.8, -0.05, -3.6), Color(0.6, 0.6, 0.58))
	Geo.box(self, "PorchWallW", Vector3(0.1, 2.6, 2.1), Vector3(0.9, 1.3, -3.6), Color(0.82, 0.8, 0.76), "the porch wall")
	Geo.box(self, "PorchWallE", Vector3(0.1, 2.6, 2.1), Vector3(2.7, 1.3, -3.6), Color(0.82, 0.8, 0.76), "the porch wall")
	Geo.box(self, "PorchWallN", Vector3(1.9, 2.6, 0.1), Vector3(1.8, 1.3, -4.7), Color(0.82, 0.8, 0.76), "the porch wall")
	Geo.box(self, "Doormat", Vector3(0.7, 0.01, 0.45), Vector3(1.8, 0.005, -2.95), Color(0.45, 0.35, 0.25), "", false)
	# The sausage. On a plate. Unattended. Someone else's barbecue leftovers.
	Geo.mesh(self, Geo.cylinder(0.14, 0.12, 0.015, 16), SAUSAGE + Vector3(0, 0.008, 0), Color(0.95, 0.95, 0.95))
	Geo.mesh(self, Geo.capsule(0.03, 0.2), SAUSAGE + Vector3(0, 0.045, 0), Color(0.6, 0.3, 0.2), Vector3(0, 30, 90))
	end_area = Area3D.new()
	end_area.name = "SausageTrigger"
	end_area.position = SAUSAGE
	end_area.collision_layer = 0
	end_area.collision_mask = Geo.LAYER_PLAYER
	var shape := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.55
	shape.shape = s
	end_area.add_child(shape)
	add_child(end_area)
	# Scent seeping under the door: a visible, diegetic lure.
	var p := CPUParticles3D.new()
	p.position = SCENT_SOURCE
	p.amount = 24
	p.lifetime = 3.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(0.4, 0.02, 0.05)
	p.direction = Vector3(0, 0.5, 1)
	p.spread = 25.0
	p.initial_velocity_min = 0.08
	p.initial_velocity_max = 0.16
	p.gravity = Vector3(0, 0.02, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	var pm := Geo.sphere(0.012, 6)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.8, 0.45, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.material = mat
	p.mesh = pm
	add_child(p)


func _build_lighting() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.62, 0.7)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.92, 0.86, 0.8)
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	# Warm light from the window side, coming in low.
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.9, 0.78)
	sun.light_energy = 0.6
	sun.rotation_degrees = Vector3(-38, -115, 0)
	sun.shadow_enabled = false
	add_child(sun)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(-0.15, 1.45, 2.2)
	lamp.light_color = Color(1.0, 0.78, 0.5)
	lamp.light_energy = 1.0
	lamp.omni_range = 4.0
	lamp.shadow_enabled = true
	add_child(lamp)
	var ceiling_light := OmniLight3D.new()
	ceiling_light.position = Vector3(0.3, 2.3, -0.4)
	ceiling_light.light_color = Color(1.0, 0.9, 0.78)
	ceiling_light.light_energy = 0.8
	ceiling_light.omni_range = 6.0
	add_child(ceiling_light)
	var porch := OmniLight3D.new()
	porch.position = Vector3(1.8, 2.0, -3.8)
	porch.light_color = Color(0.85, 0.9, 1.0)
	porch.light_energy = 0.9
	porch.omni_range = 3.0
	add_child(porch)


func _item(id: String, display: String, pos: Vector3) -> Interactable:
	var i := Interactable.new()
	i.name = id.capitalize()
	i.id = id
	i.display_name = display
	i.can_grab = true
	i.radius = 0.42
	i.position = pos
	add_child(i)
	return i


func _interactable(parent: Node3D, id: String, display: String, mark: bool, grab: bool,
		radius: float) -> Interactable:
	var i := Interactable.new()
	i.name = "Interactable"
	i.id = id
	i.display_name = display
	i.can_mark = mark
	i.can_grab = grab
	i.radius = radius
	parent.add_child(i)
	return i
