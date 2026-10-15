class_name Interactable
extends Node3D
## Something Crispee can do a specific thing to. Place it as (or under) the
## object's root. Behaviour lives in whoever listens to GameEvents; this node
## only says what is possible and where.

@export var id := ""
@export var display_name := ""
## A special claim target with its own reaction (not an ordinary mark).
@export var can_mark := false
## Small enough to carry in his mouth.
@export var can_grab := false
@export var radius := 0.55
@export var enabled := true

var claimed := false
var carried := false


func _ready() -> void:
	add_to_group("interactable")


## How well Crispee at `from`, facing `forward`, lines up with this.
## Returns < 0 when out of reach.
func reach_score(from: Vector3, forward: Vector3) -> float:
	if not enabled or carried:
		return -1.0
	var to := global_position - from
	if absf(to.y) > 0.2:
		return -1.0
	to.y = 0.0
	var dist := to.length()
	if dist > radius:
		return -1.0
	var facing := forward.dot(to.normalized()) if dist > 0.05 else 1.0
	if facing < 0.2:
		return -1.0
	return facing * 0.6 + (1.0 - dist / radius) * 0.4
