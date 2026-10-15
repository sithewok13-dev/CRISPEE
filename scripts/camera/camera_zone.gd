class_name CameraZone
extends Area3D
## A volume that reframes the camera while Crispee is inside it, e.g. a low,
## close camera under a table instead of one jammed into the tabletop.

var rig: CameraRig
var params: Dictionary = {}


static func create(parent: Node, rig_ref: CameraRig, size: Vector3, center: Vector3,
		zone_params: Dictionary) -> CameraZone:
	var z := CameraZone.new()
	z.rig = rig_ref
	z.params = zone_params
	z.position = center
	z.collision_layer = 0
	z.collision_mask = Geo.LAYER_PLAYER
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	z.add_child(shape)
	parent.add_child(z)
	return z


func _ready() -> void:
	body_entered.connect(func(b: Node3D) -> void:
		if b.is_in_group("player"):
			rig.push_zone(params))
	body_exited.connect(func(b: Node3D) -> void:
		if b.is_in_group("player"):
			rig.pop_zone(params))
