class_name TouchControls
extends Control
## On-screen controls for iPhone landscape. Handles raw multi-touch itself
## (emulated mouse only tracks one finger, which would make "hold the stick
## and press Mark" impossible) and writes intents into InputRouter.
##
## Left ~40% of the screen: floating stick. Right side: buttons, and any
## touch that misses a button drags the camera.

signal pause_pressed

const STICK_RADIUS := 78.0
const KNOB_RADIUS := 32.0
const LEFT_ZONE := 0.42
const ACTION_ICONS := {"": "·", "Hop": "Hop", "Grab": "Grab", "Drop": "Drop", "Give": "Give"}

var action_label := ""
var mark_hint := false

var _touches: Dictionary = {}  # index -> {"kind": String, "action": String}
var _stick_active := false
var _stick_origin := Vector2.ZERO
var _stick_vec := Vector2.ZERO
var _pressed: Dictionary = {}
var _font: Font


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font
	visible = InputRouter.using_touch


func set_action_label(label: String) -> void:
	action_label = label
	queue_redraw()


func set_mark_hint(on: bool) -> void:
	mark_hint = on
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		_release_all()


func _release_all() -> void:
	_touches.clear()
	_pressed.clear()
	_stick_active = false
	_stick_vec = Vector2.ZERO
	InputRouter.touch_move = Vector2.ZERO
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if not visible:
			visible = true
		var t := event as InputEventScreenTouch
		if t.pressed:
			_on_touch_down(t.index, t.position)
		else:
			_on_touch_up(t.index)
		queue_redraw()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		var info: Dictionary = _touches.get(d.index, {})
		if info.get("kind") == "stick":
			var offset := d.position - _stick_origin
			if offset.length() > STICK_RADIUS:
				# Floating stick: the base follows a thumb that overshoots.
				_stick_origin = d.position - offset.normalized() * STICK_RADIUS
				offset = d.position - _stick_origin
			_stick_vec = offset / STICK_RADIUS
			InputRouter.touch_move = _stick_vec
			queue_redraw()
		elif info.get("kind") == "camera":
			InputRouter.add_touch_camera_drag(d.relative)


func _on_touch_down(index: int, pos: Vector2) -> void:
	for b in _buttons():
		if pos.distance_to(b.pos) <= b.r * 1.2:
			_touches[index] = {"kind": "button", "action": b.action}
			_pressed[b.action] = true
			if b.action == "pause":
				pause_pressed.emit()
			else:
				InputRouter.press_touch(b.action)
				Input.vibrate_handheld(15)
			return
	if pos.x < size.x * LEFT_ZONE:
		_touches[index] = {"kind": "stick"}
		_stick_active = true
		_stick_origin = pos
		_stick_vec = Vector2.ZERO
	else:
		_touches[index] = {"kind": "camera"}


func _on_touch_up(index: int) -> void:
	var info: Dictionary = _touches.get(index, {})
	_touches.erase(index)
	match info.get("kind", ""):
		"stick":
			_stick_active = false
			_stick_vec = Vector2.ZERO
			InputRouter.touch_move = Vector2.ZERO
		"button":
			_pressed.erase(info.action)


func _margins() -> Dictionary:
	var m := {"left": 24.0, "right": 24.0, "top": 16.0, "bottom": 20.0}
	if not OS.has_feature("mobile"):
		return m
	var win := Vector2(DisplayServer.window_get_size())
	var safe := DisplayServer.get_display_safe_area()
	if win.x <= 0.0 or safe.size.x <= 0:
		return m
	var k := size / win
	m["left"] += safe.position.x * k.x
	m["right"] += (win.x - safe.end.x) * k.x
	m["top"] += safe.position.y * k.y
	m["bottom"] += (win.y - safe.end.y) * k.y
	return m


func _buttons() -> Array:
	var m := _margins()
	var br := Vector2(size.x - m.right - 96.0, size.y - m.bottom - 92.0)
	return [
		{"action": "action", "label": ACTION_ICONS.get(action_label, action_label), "pos": br, "r": 64.0},
		{"action": "mark", "label": "Mark", "pos": br + Vector2(-150.0, 22.0), "r": 50.0},
		{"action": "sniff", "label": "Sniff", "pos": br + Vector2(-122.0, -112.0), "r": 44.0},
		{"action": "bark", "label": "Bark", "pos": br + Vector2(8.0, -150.0), "r": 44.0},
		{"action": "pause", "label": "II", "pos": Vector2(size.x - m.right - 30.0, m.top + 34.0), "r": 30.0},
	]


func _draw() -> void:
	var m := _margins()
	var faint := Color(1, 1, 1, 0.10)
	var ring := Color(1, 1, 1, 0.45)
	if _stick_active:
		draw_circle(_stick_origin, STICK_RADIUS, faint)
		draw_arc(_stick_origin, STICK_RADIUS, 0.0, TAU, 48, ring, 2.0, true)
		draw_circle(_stick_origin + _stick_vec * STICK_RADIUS, KNOB_RADIUS, Color(1, 1, 1, 0.4))
	else:
		var home := Vector2(m.left + 130.0, size.y - m.bottom - 130.0)
		draw_arc(home, STICK_RADIUS, 0.0, TAU, 48, Color(1, 1, 1, 0.18), 2.0, true)
		draw_circle(home, KNOB_RADIUS, Color(1, 1, 1, 0.12))

	for b in _buttons():
		var pressed: bool = _pressed.get(b.action, false)
		var idle: bool = b.action == "action" and action_label == ""
		var fill := Color(1, 1, 1, 0.35) if pressed else Color(0, 0, 0, 0.30)
		var edge := ring
		if b.action == "mark" and mark_hint:
			edge = Color(1.0, 0.8, 0.3, 0.95)
			fill = Color(0.35, 0.25, 0.05, 0.45) if not pressed else fill
		if idle:
			edge = Color(1, 1, 1, 0.18)
		draw_circle(b.pos, b.r, fill)
		draw_arc(b.pos, b.r, 0.0, TAU, 48, edge, 3.0 if b.action == "mark" and mark_hint else 2.0, true)
		var fs := 26 if b.r > 40.0 else 22
		var text: String = b.label
		var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var col := Color(1, 1, 1, 0.35 if idle else 0.95)
		draw_string(_font, Vector2(b.pos.x - w * 0.5, b.pos.y + fs * 0.35), text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
