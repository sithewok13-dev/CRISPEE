class_name Crispee
extends CharacterBody3D
## Direct control of Crispee. Reads intents from InputRouter, moves, hops,
## and announces what he did on GameEvents. Knows nothing about puzzles.

signal context_changed(action_label: String)
signal mark_hint_changed(special_nearby: bool)

const RUN_SPEED := 2.7
const ACCEL := 11.0
const DECEL := 14.0
const TURN_RATE := 11.0
const GRAVITY := 14.0
## Ledges this low he simply walks up (pet stairs).
const STEP_HEIGHT := 0.17
## The most he can hop up. A couch seat (0.45) is out of reach on purpose.
const MAX_HOP_UP := 0.28
const HOP_PROBES := [0.28, 0.4, 0.52]
const MARK_REACH := 0.42
const MARKS_BEFORE_EMPTY := 5
const EMPTY_SECONDS := 8.0

const NOTHING_TO_MARK := [
	"[Open floor. Unclaimable. Disappointing.]",
	"[Nothing here worth owning.]",
	"[He needs something vertical. A statement needs a surface.]",
]
const EMPTY_LINES := [
	"[Nothing left. Dignity intact.]",
	"[The tank is empty. The ambition is not.]",
	"[A ceremonial gesture only.]",
]

enum State { FREE, HOPPING, ACTING }

var state := State.FREE
var body: CrispeeBody
var carried: Interactable = null
var input_enabled := true
## Where dropped items go (the level root).
var drop_parent: Node3D
## Returns the camera's yaw so stick input is camera-relative.
var camera_yaw_provider: Callable

var hop_target: Variant = null
var _focus: Interactable = null
var _mark_focus: Interactable = null
var _receiver: Node3D = null
var _context := ""
var _mark_hint := false

var _hop_from := Vector3.ZERO
var _hop_to := Vector3.ZERO
var _hop_t := 0.0
var _hop_dur := 0.3
var _act_timer := 0.0
var _act_done := Callable()
var _time := 0.0
var _recent_marks: Array[float] = []
var _empty_until := -1.0
var _puddles: Array[Node3D] = []


func _ready() -> void:
	add_to_group("player")
	collision_layer = Geo.LAYER_PLAYER
	collision_mask = Geo.LAYER_WORLD | Geo.LAYER_HUMAN
	floor_snap_length = 0.12
	floor_max_angle = deg_to_rad(50.0)
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.12
	cap.height = 0.3
	shape.shape = cap
	shape.position.y = 0.15
	add_child(shape)
	body = CrispeeBody.new()
	add_child(body)


func teleport(pos: Vector3, yaw: float = rotation.y) -> void:
	global_position = pos
	rotation.y = yaw
	velocity = Vector3.ZERO
	state = State.FREE


func forward() -> Vector3:
	var f := -global_transform.basis.z
	f.y = 0.0
	return f.normalized()


func _physics_process(delta: float) -> void:
	_time += delta
	var move_in := InputRouter.get_move() if input_enabled else Vector2.ZERO

	if state == State.HOPPING:
		_update_hop(delta)
		return
	if state == State.ACTING:
		move_in = Vector2.ZERO
		_act_timer -= delta
		if _act_timer <= 0.0:
			state = State.FREE
			body.set_pose("carry" if carried else "idle")
			if _act_done.is_valid():
				var done := _act_done
				_act_done = Callable()
				done.call()

	var hv := Vector3(velocity.x, 0.0, velocity.z)
	var mag := clampf(move_in.length(), 0.0, 1.0)
	if mag > 0.12:
		var yaw: float = camera_yaw_provider.call() if camera_yaw_provider.is_valid() else 0.0
		var dir := Vector3(move_in.x, 0.0, move_in.y).rotated(Vector3.UP, yaw).normalized()
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 1.0 - exp(-TURN_RATE * delta))
		var align := clampf(forward().dot(dir) * 0.5 + 0.5, 0.25, 1.0)
		var target_speed := RUN_SPEED * pow(mag, 1.5)
		hv = hv.move_toward(dir * target_speed * align, ACCEL * delta)
	else:
		hv = hv.move_toward(Vector3.ZERO, DECEL * delta)
	velocity.x = hv.x
	velocity.z = hv.z
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	var was_on_floor := is_on_floor()
	var fall_speed := velocity.y
	move_and_slide()
	if is_on_floor() and not was_on_floor and fall_speed < -1.2:
		body.land()
		Sfx.play("land")
	_try_step_up(hv)

	_update_context()
	_handle_buttons()
	body.animate(delta, hv.length(), is_on_floor(), velocity.y)


# --- Context -----------------------------------------------------------------

func _update_context() -> void:
	_focus = null
	_receiver = null
	hop_target = null
	_mark_focus = null
	var label := ""
	if state == State.FREE and is_on_floor():
		_mark_focus = _best_interactable(func(i: Interactable) -> bool: return i.can_mark and not i.claimed)
		if carried:
			_receiver = _find_receiver()
			label = "Give" if _receiver else "Drop"
		else:
			_focus = _best_interactable(func(i: Interactable) -> bool: return i.can_grab)
			if _focus:
				label = "Grab"
			else:
				hop_target = find_hop()
				if hop_target != null:
					label = "Hop"
	if label != _context:
		_context = label
		context_changed.emit(label)
	var hint := _mark_focus != null
	if hint != _mark_hint:
		_mark_hint = hint
		mark_hint_changed.emit(hint)
	var look: Node3D = _focus if _focus else (_mark_focus if _mark_focus else _receiver)
	body.look_target = look.global_position + Vector3.UP * 0.1 if look else null


func _best_interactable(filter: Callable) -> Interactable:
	var best: Interactable = null
	var best_score := 0.0
	for node in get_tree().get_nodes_in_group("interactable"):
		var i := node as Interactable
		if i == null or not filter.call(i):
			continue
		var s := i.reach_score(global_position, forward())
		if s > best_score:
			best_score = s
			best = i
	return best


func _find_receiver() -> Node3D:
	for node in get_tree().get_nodes_in_group("receiver"):
		var r := node as Node3D
		var d := r.global_position - global_position
		if absf(d.y) < 0.4 and Vector2(d.x, d.z).length() < 1.0 and r.call("accepts", carried):
			return r
	return null


## Finds a surface ahead that is too high to walk onto but low enough to hop.
## Returns {"to": Vector3, "height": float} or null.
func find_hop() -> Variant:
	var space := get_world_3d().direct_space_state
	var base := global_position
	var fwd := forward()
	for d in HOP_PROBES:
		var from: Vector3 = base + fwd * d + Vector3.UP * (MAX_HOP_UP + 0.04)
		var to: Vector3 = base + fwd * d + Vector3.UP * (STEP_HEIGHT - 0.01)
		var hit := _ray(space, from, to)
		if hit.is_empty() or hit.normal.y < 0.8:
			continue
		var landing: Vector3 = hit.position
		# Room to stand on top?
		if not _ray(space, landing + Vector3.UP * 0.02, landing + Vector3.UP * 0.3).is_empty():
			continue
		# Nothing in the way of the jump arc?
		var h := landing.y - base.y
		if not _ray(space, base + Vector3.UP * (h + 0.14), landing + Vector3.UP * 0.14).is_empty():
			continue
		return {"to": landing + fwd * 0.08, "height": h}
	return null


func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to, Geo.LAYER_WORLD, [get_rid()])
	return space.intersect_ray(q)


func _try_step_up(hv: Vector3) -> void:
	if not is_on_floor() or not is_on_wall() or hv.length() < 0.1:
		return
	var dir := hv.normalized()
	var space := get_world_3d().direct_space_state
	var probe := global_position + dir * 0.2
	var hit := _ray(space, probe + Vector3.UP * (STEP_HEIGHT + 0.02), probe + Vector3.UP * 0.01)
	if hit.is_empty() or hit.normal.y < 0.8:
		return
	var h: float = hit.position.y - global_position.y
	if h > 0.01 and h <= STEP_HEIGHT:
		global_position += Vector3.UP * (h + 0.005) + dir * 0.04


# --- Actions -----------------------------------------------------------------

func _handle_buttons() -> void:
	var act := InputRouter.consume_pressed("action")
	var mark := InputRouter.consume_pressed("mark")
	var bark := InputRouter.consume_pressed("bark")
	var sniff := InputRouter.consume_pressed("sniff")
	if not input_enabled or state != State.FREE:
		return
	if act:
		do_action()
	elif mark:
		do_mark()
	elif bark:
		do_bark()
	elif sniff:
		do_sniff()


func do_action() -> void:
	if carried:
		if _receiver:
			_give(_receiver)
		else:
			drop()
	elif _focus:
		_grab(_focus)
	elif hop_target != null:
		_start_hop(hop_target)


func do_bark() -> void:
	if carried:
		drop()  # a dog can't bark with his mouth full
	_start_act("bark", 0.45)
	Sfx.play("bark", randf_range(0.95, 1.08))
	GameEvents.barked.emit(global_position)


func do_sniff() -> void:
	_start_act("sniff", 1.3)
	GameEvents.sniffed.emit(global_position + forward() * 0.1)


func do_mark() -> void:
	if carried:
		drop()
	_recent_marks = _recent_marks.filter(func(t: float) -> bool: return _time - t < 25.0)
	if _time < _empty_until or _recent_marks.size() >= MARKS_BEFORE_EMPTY:
		if _time >= _empty_until:
			_empty_until = _time + EMPTY_SECONDS
			_recent_marks.clear()
		_start_act("empty", 1.6)
		Sfx.play("empty")
		GameEvents.say(EMPTY_LINES.pick_random())
		return
	var target := _best_interactable(func(i: Interactable) -> bool: return i.can_mark and not i.claimed)
	if target:
		_recent_marks.append(_time)
		_face(target.global_position)
		_start_act("mark", 1.4, _finish_special_mark.bind(target))
		Sfx.play("trickle")
		return
	var surf := _find_mark_surface()
	if surf.is_empty():
		_start_act("sniff", 0.9)
		GameEvents.say(NOTHING_TO_MARK.pick_random())
		return
	_recent_marks.append(_time)
	_start_act("mark", 1.2, _finish_ordinary_mark.bind(surf))
	Sfx.play("trickle")


func _finish_special_mark(target: Interactable) -> void:
	target.claimed = true
	WorldState.add_claim(target.id)
	_spawn_puddle(target.global_position.lerp(global_position, 0.5))
	Sfx.play("claim")
	GameEvents.marked.emit(target, target.display_name, target.global_position)


func _finish_ordinary_mark(surf: Dictionary) -> void:
	WorldState.ordinary_marks += 1
	_spawn_puddle(surf.point + surf.normal * 0.05)
	GameEvents.marked.emit(null, surf.name, surf.point)


func _find_mark_surface() -> Dictionary:
	var space := get_world_3d().direct_space_state
	var origin := global_position + Vector3.UP * 0.1
	var right := forward().cross(Vector3.UP)
	for dir in [right, forward(), -right, -forward()]:
		var hit := _ray(space, origin, origin + dir * MARK_REACH)
		if hit.is_empty() or absf(hit.normal.y) > 0.5:
			continue
		var collider: Object = hit.collider
		if collider and collider.has_meta("mark_name"):
			return {"name": collider.get_meta("mark_name"), "point": hit.position, "normal": hit.normal}
	return {}


func _spawn_puddle(at: Vector3) -> void:
	if drop_parent == null:
		return
	var p := Geo.mesh(drop_parent, Geo.cylinder(0.07, 0.07, 0.003, 14),
			Vector3(at.x, global_position.y + 0.003, at.z), Color(0.82, 0.72, 0.3, 0.35))
	p.scale = Vector3(randf_range(0.8, 1.2), 1.0, randf_range(0.8, 1.2))
	_puddles.append(p)
	if _puddles.size() > 24:
		_puddles.pop_front().queue_free()


func _grab(item: Interactable) -> void:
	carried = item
	item.carried = true
	item.reparent(body.mouth, false)
	item.position = Vector3.ZERO
	item.rotation = Vector3(0, PI * 0.5, 0)
	body.set_pose("carry")
	Sfx.play("pickup")
	if item.has_meta("squeaks"):
		Sfx.play("squeak")
	GameEvents.item_picked_up.emit(item)


func drop() -> void:
	if not carried:
		return
	var item := carried
	carried = null
	item.carried = false
	var spot := global_position + forward() * 0.22
	item.reparent(drop_parent if drop_parent else get_parent(), false)
	item.global_position = Vector3(spot.x, global_position.y, spot.z)
	item.rotation = Vector3(0, rotation.y, 0)
	body.set_pose("idle")
	GameEvents.item_dropped.emit(item)


func _give(receiver: Node3D) -> void:
	var item := carried
	carried = null
	item.carried = false
	body.set_pose("idle")
	receiver.call("receive_item", item)
	GameEvents.item_given.emit(item, receiver)


func _start_act(pose: String, duration: float, done: Callable = Callable()) -> void:
	state = State.ACTING
	_act_timer = duration
	_act_done = done
	velocity.x = 0.0
	velocity.z = 0.0
	body.set_pose(pose)


func _face(point: Vector3) -> void:
	var d := point - global_position
	if Vector2(d.x, d.z).length() > 0.01:
		rotation.y = atan2(-d.x, -d.z)


func _start_hop(target: Dictionary) -> void:
	state = State.HOPPING
	_hop_from = global_position
	_hop_to = target.to
	_hop_t = 0.0
	_hop_dur = 0.3 + target.height * 0.5
	body.set_pose("hop")
	Sfx.play("hop")


func _update_hop(delta: float) -> void:
	_hop_t = minf(_hop_t + delta / _hop_dur, 1.0)
	var p := _hop_from.lerp(_hop_to, _hop_t)
	p.y += sin(_hop_t * PI) * 0.14
	global_position = p
	body.animate(delta, 0.0, false, cos(_hop_t * PI) * 2.0)
	if _hop_t >= 1.0:
		state = State.FREE
		velocity = Vector3.ZERO
		body.set_pose("carry" if carried else "idle")
		body.land()
		Sfx.play("land")
