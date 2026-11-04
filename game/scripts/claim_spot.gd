extends Area3D
class_name ClaimSpot
## A place Crispee can mark. Owning it may change the world (world_key).

var key := ""
var label := ""
var reaction := ""
var world_key := ""
var glow: MeshInstance3D
var puddle: MeshInstance3D
var _t := 0.0

static func make(p_key: String, p_label: String, p_reaction: String, pos: Vector3, size: Vector3, p_world_key := "") -> ClaimSpot:
	var s := ClaimSpot.new()
	s.key = p_key; s.label = p_label; s.reaction = p_reaction; s.world_key = p_world_key
	s.name = "Spot_" + p_key
	s.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new(); box.size = size
	shape.shape = box
	s.add_child(shape)
	s.collision_layer = 0
	s.collision_mask = 2
	s.monitoring = true
	# Pee Vision glow: unshaded, drawn through walls
	var g := MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = 0.16; sm.height = 0.32
	g.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.85, 0.2, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mat.render_priority = 10
	g.material_override = mat
	g.visible = false
	s.add_child(g)
	s.glow = g
	return s

func is_owned() -> bool:
	return Game.owned.has(key)

func _process(delta: float) -> void:
	_t += delta
	if glow.visible:
		if is_owned():
			glow.scale = Vector3.ONE * 1.15
			glow.material_override.albedo_color = Color(1.0, 0.95, 0.6, 0.95)
		else:
			var p := 1.0 + 0.25 * sin(_t * 5.0)
			glow.scale = Vector3.ONE * p
			glow.material_override.albedo_color = Color(1.0, 0.8, 0.1, 0.85)

func set_vision(on: bool) -> void:
	glow.visible = on

func show_puddle() -> void:
	if puddle:
		return
	puddle = MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = 0.1; cm.bottom_radius = 0.12; cm.height = 0.01
	puddle.mesh = cm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.85, 0.25, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puddle.material_override = mat
	puddle.position = Vector3(0, -get_child(0).shape.size.y * 0.5 + 0.006, 0)
	add_child(puddle)
