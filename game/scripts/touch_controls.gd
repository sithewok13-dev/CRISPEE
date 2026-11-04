extends CanvasLayer
## Left half: virtual stick. Right side: PEE, JUMP, ACT, POWER. Right half swipe nudges camera.

signal stick_changed(dir)
signal button_pressed(name)
signal button_released(name)
signal camera_nudge(amount)

var stick_base: Control
var stick_knob: Control
var _stick_touch := -1
var _stick_origin := Vector2.ZERO
var _cam_touch := -1
var _cam_last := Vector2.ZERO
var buttons := {}
var _btn_touch := {}
const RADIUS := 70.0

func _ready() -> void:
	layer = 8
	var root := Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT); root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var rest := _circle(root, 150, Color(1, 1, 1, 0.04), Color(1, 1, 1, 0.22))
	rest.anchor_left = 0.0; rest.anchor_right = 0.0; rest.anchor_top = 1.0; rest.anchor_bottom = 1.0
	rest.offset_left = 80; rest.offset_top = -230; rest.offset_right = 230; rest.offset_bottom = -80
	stick_base = _circle(root, 170, Color(1, 1, 1, 0.08), Color(1, 1, 1, 0.45)); stick_base.visible = false
	stick_knob = _circle(root, 60, Color(1, 1, 1, 0.55), Color(0, 0, 0, 0)); stick_knob.visible = false
	var defs := [["PEE", Vector2(-160, -160), Color(0.94, 0.78, 0.16, 0.55), Color(1, 0.89, 0.42)],
		["JUMP", Vector2(-280, -130), Color(0, 0, 0, 0.35), Color(1, 1, 1, 0.6)],
		["ACT", Vector2(-280, -250), Color(0, 0, 0, 0.35), Color(1, 1, 1, 0.6)],
		["POWER", Vector2(-160, -280), Color(0.31, 0.16, 0.63, 0.5), Color(0.79, 0.66, 1.0)]]
	for d in defs:
		var b := _circle(root, 88, d[2], d[3])
		b.anchor_left = 1.0; b.anchor_right = 1.0; b.anchor_top = 1.0; b.anchor_bottom = 1.0
		b.offset_left = d[1].x; b.offset_top = d[1].y; b.offset_right = d[1].x + 88; b.offset_bottom = d[1].y + 88
		var l := Label.new(); l.text = d[0]; l.set_anchors_preset(Control.PRESET_FULL_RECT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 16); l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(l)
		buttons[d[0]] = b

func _circle(parent: Control, size: float, fill: Color, border: Color) -> Control:
	var p := Panel.new()
	var sb := StyleBoxFlat.new(); sb.bg_color = fill; sb.set_corner_radius_all(int(size / 2)); sb.set_border_width_all(3); sb.border_color = border
	p.add_theme_stylebox_override("panel", sb)
	p.size = Vector2(size, size)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p

func _button_at(pos: Vector2) -> String:
	for n in buttons:
		var b: Control = buttons[n]
		if (b.global_position + b.size * 0.5).distance_to(pos) <= b.size.x * 0.6:
			return n
	return ""

func _unhandled_input(event: InputEvent) -> void:
	var vp := get_viewport().get_visible_rect().size
	if event is InputEventScreenTouch:
		var pos: Vector2 = event.position
		if event.pressed:
			var bn := _button_at(pos)
			if bn != "":
				_btn_touch[event.index] = bn
				button_pressed.emit(bn)
			elif pos.x < vp.x * 0.5 and _stick_touch < 0:
				_stick_touch = event.index; _stick_origin = pos
				stick_base.position = pos - stick_base.size * 0.5; stick_base.visible = true
				stick_knob.position = pos - stick_knob.size * 0.5; stick_knob.visible = true
			elif _cam_touch < 0:
				_cam_touch = event.index; _cam_last = pos
		else:
			if _btn_touch.has(event.index):
				button_released.emit(_btn_touch[event.index]); _btn_touch.erase(event.index)
			if event.index == _stick_touch:
				_stick_touch = -1; stick_base.visible = false; stick_knob.visible = false
				stick_changed.emit(Vector2.ZERO)
			if event.index == _cam_touch:
				_cam_touch = -1
	elif event is InputEventScreenDrag:
		if event.index == _stick_touch:
			var d: Vector2 = event.position - _stick_origin
			if d.length() > RADIUS: d = d.normalized() * RADIUS
			stick_knob.position = _stick_origin + d - stick_knob.size * 0.5
			stick_changed.emit(d / RADIUS)
		elif event.index == _cam_touch:
			var dx: float = event.position.x - _cam_last.x
			_cam_last = event.position
			camera_nudge.emit(-dx * 0.006)
