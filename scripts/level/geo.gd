class_name Geo
## Greybox construction helpers. Real rooms will be authored as scenes with
## proper art; these keep the prototype readable and cheap to change.

const LAYER_WORLD := 1
const LAYER_PLAYER := 2
const LAYER_HUMAN := 4

static var _materials: Dictionary = {}


static func mat(color: Color, roughness: float = 0.85) -> StandardMaterial3D:
	var key := "%s/%s" % [color.to_html(), roughness]
	if not _materials.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = roughness
		if color.a < 1.0:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_materials[key] = m
	return _materials[key]


## A solid box. `mark_name` makes its sides a valid ordinary marking spot
## ("the couch"); leave empty for things not worth claiming.
static func box(parent: Node, name: String, size: Vector3, center: Vector3, color: Color,
		mark_name: String = "", collide: bool = true) -> Node3D:
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	mesh.material_override = mat(color)
	if not collide:
		mesh.name = name
		mesh.position = center
		parent.add_child(mesh)
		return mesh
	var body := StaticBody3D.new()
	body.name = name
	body.position = center
	body.collision_layer = LAYER_WORLD
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	body.add_child(shape)
	body.add_child(mesh)
	if mark_name != "":
		body.set_meta("mark_name", mark_name)
	parent.add_child(body)
	return body


static func mesh(parent: Node, m: Mesh, pos: Vector3, color: Color, rot_deg: Vector3 = Vector3.ZERO,
		scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat(color)
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = scale
	parent.add_child(mi)
	return mi


static func sphere(radius: float, segments: int = 12) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = segments
	s.rings = maxi(segments / 2, 4)
	return s


static func capsule(radius: float, height: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = radius
	c.height = height
	c.radial_segments = 12
	c.rings = 4
	return c


static func cylinder(top: float, bottom: float, height: float, segments: int = 10) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = height
	c.radial_segments = segments
	c.rings = 1
	return c


static func label(parent: Node, text: String, pos: Vector3, size: int = 48,
		color: Color = Color(0.1, 0.1, 0.1)) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.002
	l.modulate = color
	l.outline_size = 0
	l.position = pos
	parent.add_child(l)
	return l
