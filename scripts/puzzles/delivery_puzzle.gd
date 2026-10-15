class_name DeliveryPuzzle
extends Node
## "The Delivery": the first playable's puzzle and reactions.
##
## Critical path:  claim the box -> the human moves it beside the bookshelf
## (the claim becomes a step) -> hop box -> shelf -> grab leash -> give it to
## the human -> door opens -> sausage.
## Optional: ordinary marks, barking at the door, the slippers, sock and toy.
##
## Everything here reacts to GameEvents and uses the level's exposed pieces,
## so the same systems can host the next room's puzzle.

const ORDINARY_LINES := [
	"Not %s, Crispee.",
	"We've talked about this.",
	"That's two.",
	"I'm getting the spray.",
	"Is this a statement?",
	"Fine. I'll update the inventory.",
	"At this rate you'll own the whole room by dinner.",
]
const ORDINARY_REPEAT := ["Noted.", "Mm.", "Of course you did.", "Yours. Got it."]
const BARK_LINES := ["Mm-hm.", "I hear you.", "Yes. Noted.", "Use your inside voice.", "Okay, okay."]

var level: LivingRoom
var player: Crispee
var human: Human

var _ordinary_count := 0
var _bark_count := 0
var _door_barks := 0
var _sniffs := 0
var _last_reaction := -10.0
var _time := 0.0
var _finished := false


func setup(room: LivingRoom, crispee: Crispee, person: Human) -> void:
	level = room
	player = crispee
	human = person
	human.accept_filter = func(item: Node) -> bool:
		return item is Interactable and (item as Interactable).id in ["leash", "sock", "toy"]
	human.on_item_received = _on_item_received
	GameEvents.marked.connect(_on_marked)
	GameEvents.barked.connect(_on_barked)
	GameEvents.sniffed.connect(_on_sniffed)
	level.end_area.body_entered.connect(_on_end_area)


func _process(delta: float) -> void:
	_time += delta


## Put the world back the way the saved flags describe it.
func apply_state() -> void:
	if WorldState.has_flag("box_claimed"):
		level.box_root.position = LivingRoom.BOX_SHELF_SPOT
		level.box_label.visible = true
		level.box_mark.claimed = true
	if WorldState.is_claimed("slippers"):
		level.slippers.claimed = true
		level.slippers_label.visible = true
	if WorldState.has_flag("door_open"):
		human.global_position = LivingRoom.DOOR_INSIDE
		human.rotation.y = 0.0
		human.seated = false
		human.hold(level.leash)
		level.set_door_open(true, false)


func objective_hint() -> String:
	if WorldState.has_flag("door_open"):
		return "Sausage."
	if player.carried == level.leash:
		return "Bring the leash to someone with thumbs."
	if WorldState.has_flag("box_claimed"):
		return "The box is a step now. The shelf is not out of reach."
	return "Something smells good beyond the door."


# --- Reactions ------------------------------------------------------------------

func _on_marked(target: Node, surface_name: String, _pos: Vector3) -> void:
	var t := target as Interactable
	if t == null:
		_react_ordinary(surface_name)
	elif t.id == "box":
		_on_box_claimed()
	elif t.id == "slippers":
		level.slippers_label.visible = true
		if not human.busy():
			human.run([Human.say("Those were my good slippers.", 2.4), Human.wait(1.6),
					Human.say("They're yours now. Obviously.", 2.6)])


func _react_ordinary(surface_name: String) -> void:
	if human.busy() or _time - _last_reaction < 2.0:
		return
	_last_reaction = _time
	var line: String
	if _ordinary_count < ORDINARY_LINES.size():
		line = ORDINARY_LINES[_ordinary_count]
		if "%s" in line:
			line = line % surface_name
	else:
		line = ORDINARY_REPEAT.pick_random()
	_ordinary_count += 1
	GameEvents.say(line, Human.SPEAKER, 2.6)


func _on_box_claimed() -> void:
	WorldState.set_flag("box_claimed")
	human.interrupt()
	human.run([
		Human.say("...Did you just claim the delivery?", 2.6),
		Human.walk(LivingRoom.BOX_HUMAN_STAND),
		Human.face(level.box_root.global_position),
		Human.wait(0.5),
		Human.say("Fine. It's yours.", 2.0),
		Human.call_fn(_label_box),
		Human.wait(0.8),
		Human.call_fn(func() -> void: human.hold(level.box_root)),
		Human.say("It can live by the bookshelf. With your other things.", 3.0),
		Human.walk(LivingRoom.SHELF_HUMAN_STAND),
		Human.face(LivingRoom.BOX_SHELF_SPOT),
		Human.call_fn(_place_box_by_shelf),
		Human.wait(0.6),
		Human.walk(LivingRoom.HUMAN_SEAT),
		Human.sit(),
	])


func _on_barked(pos: Vector3) -> void:
	if human.busy() or _time - _last_reaction < 1.5:
		return
	_last_reaction = _time
	_bark_count += 1
	if WorldState.has_flag("door_open"):
		GameEvents.say("Go on, then. Out.", Human.SPEAKER, 2.0)
		return
	var near_door := pos.distance_to(LivingRoom.DOOR_INSIDE) < 1.4
	if near_door and human.seated:
		_door_barks += 1
		var verdict := "Nobody's there. Just the neighbour's barbecue." if _door_barks == 1 \
				else "Still nobody, Crispee. The door stays shut."
		human.run([
			Human.say("Hm? Someone at the door?", 2.0),
			Human.walk(LivingRoom.DOOR_INSIDE + Vector3(0.0, 0.0, 0.25)),
			Human.face(LivingRoom.DOOR_INSIDE + Vector3(0.0, 0.0, -1.0)),
			Human.wait(0.9),
			Human.say(verdict, 2.8),
			Human.wait(0.6),
			Human.walk(LivingRoom.HUMAN_SEAT),
			Human.sit(),
		])
	else:
		GameEvents.say(BARK_LINES[(_bark_count - 1) % BARK_LINES.size()], Human.SPEAKER, 1.8)


func _on_item_received(item: Node) -> void:
	var i := item as Interactable
	match i.id:
		"leash":
			WorldState.set_flag("door_open")
			human.run([
				Human.say("Oh. A walk? ...Fine. Fine.", 2.4),
				Human.walk(LivingRoom.DOOR_INSIDE),
				Human.face(LivingRoom.DOOR_INSIDE + Vector3(0.0, 0.0, -1.0)),
				Human.call_fn(_open_door),
				Human.wait(0.8),
				Human.face(player.global_position),
				Human.say("Go on, then. Don't claim the neighbours.", 3.0),
			])
		"sock":
			human.run([
				Human.say("Thank you...?", 1.8),
				Human.call_fn(func() -> void: human.release(i, level, LivingRoom.DESK_TOP)),
			])
		"toy":
			human.run([
				Human.say("I am not throwing that.", 2.0),
				Human.wait(1.4),
				Human.say("...Once.", 1.4),
				Human.call_fn(func() -> void: _toss(i)),
			])


func _toss(item: Interactable) -> void:
	var start := human.hands.global_position
	human.release(item, level, start)
	var land := Vector3(randf_range(-1.8, 0.8), 0.0, randf_range(-1.2, 1.0))
	var tw := create_tween()
	tw.tween_method(_arc.bind(item, start, land, 0.8), 0.0, 1.0, 0.9)
	tw.tween_callback(Sfx.play.bind("squeak"))


func _on_sniffed(nose: Vector3) -> void:
	_sniffs += 1
	var from: Vector3
	var text: String
	if WorldState.has_flag("door_open"):
		from = LivingRoom.SAUSAGE
		text = "[SAUSAGE. Close. Unattended. Destiny.]"
	elif player.carried == level.leash:
		from = human.global_position + Vector3.UP * 0.9
		text = "[The leash. The one with thumbs understands leashes.]"
	elif WorldState.has_flag("box_claimed") and not human.busy():
		from = level.leash.global_position
		text = "[Leather. Walks. The outside. Up there, on the shelf.]"
	elif WorldState.has_flag("box_claimed"):
		from = level.box_root.global_position
		text = "[His box is being relocated. Ownership has consequences.]"
	elif _sniffs % 2 == 1:
		from = LivingRoom.SCENT_SOURCE
		text = "[Sausage. Outside. Behind a door, as usual.]"
	else:
		from = level.box_root.global_position + Vector3.UP * 0.2
		text = "[This box smells of strangers. Nobody has claimed it.]"
	GameEvents.say(text, "", 3.2)
	_scent_trail(from, nose)


## A short stream of glowing motes from the scent's source to his nose.
func _scent_trail(from: Vector3, to: Vector3) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.82, 0.4, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mesh := Geo.sphere(0.018, 6)
	for n in 12:
		var mote := MeshInstance3D.new()
		mote.mesh = mesh
		mote.material_override = mat
		mote.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		level.add_child(mote)
		mote.global_position = from
		var wobble := Vector3(randf_range(-0.15, 0.15), randf_range(0.0, 0.2), randf_range(-0.15, 0.15))
		var tw := mote.create_tween()
		tw.tween_interval(n * 0.08)
		tw.tween_method(_wobble.bind(mote, from, to, wobble), 0.0, 1.0, 1.4)
		tw.tween_callback(mote.queue_free)


func _label_box() -> void:
	level.box_label.visible = true
	Sfx.play("pickup", 0.6)


func _place_box_by_shelf() -> void:
	human.release(level.box_root, level, LivingRoom.BOX_SHELF_SPOT)
	Sfx.play("land", 0.7)


func _open_door() -> void:
	level.set_door_open(true)
	Sfx.play("door")


# Tween callbacks: bind() appends its arguments, so the tweened value is first.
func _arc(t: float, node: Node3D, from: Vector3, to: Vector3, height: float) -> void:
	node.global_position = from.lerp(to, t) + Vector3.UP * sin(t * PI) * height


func _wobble(t: float, node: Node3D, from: Vector3, to: Vector3, wobble: Vector3) -> void:
	node.global_position = from.lerp(to, t) + wobble * sin(t * PI)


func _on_end_area(body: Node3D) -> void:
	if _finished or body != player or not WorldState.has_flag("door_open"):
		return
	_finished = true
	player.input_enabled = false
	InputRouter.clear()
	GameEvents.say("[Sausage acquired. Territory: expanding.]", "", 3.0)
	WorldState.set_flag("slice_complete")
	get_tree().create_timer(2.8).timeout.connect(func() -> void: GameEvents.slice_completed.emit())
