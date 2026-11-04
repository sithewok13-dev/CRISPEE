extends CanvasLayer
## Tune the feel on the phone: sliders for jump, gravity, speed and camera. Values persist.

const SAVE := "user://feel.json"
var dog: Crispee
var rig: Node3D
var panel: PanelContainer
var rows := {}
var toggle: Button

func _ready() -> void:
	layer = 12
	var root := Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT); root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	toggle = Button.new(); toggle.text = "FEEL"
	toggle.anchor_left = 1.0; toggle.anchor_right = 1.0; toggle.anchor_top = 0.0; toggle.anchor_bottom = 0.0
	toggle.offset_left = -300; toggle.offset_top = 22; toggle.offset_right = -244; toggle.offset_bottom = 54
	toggle.add_theme_font_size_override("font_size", 12)
	toggle.pressed.connect(func(): panel.visible = not panel.visible)
	root.add_child(toggle)
	panel = PanelContainer.new()
	panel.anchor_left = 0.5; panel.anchor_right = 0.5; panel.anchor_top = 0.0; panel.anchor_bottom = 0.0
	panel.offset_left = -230; panel.offset_top = 70; panel.offset_right = 230; panel.offset_bottom = 330
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0, 0, 0, 0.8); sb.set_corner_radius_all(12)
	sb.content_margin_left = 16; sb.content_margin_right = 16; sb.content_margin_top = 12; sb.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", sb)
	panel.visible = false
	root.add_child(panel)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 6); panel.add_child(box)
	_row(box, "jump_height", "Jump height (m)", 0.3, 1.0, 0.01, func(): return dog.jump_height, func(v): dog.jump_height = v)
	_row(box, "gravity", "Gravity", 6.0, 30.0, 0.1, func(): return dog.gravity, func(v): dog.gravity = v)
	_row(box, "speed", "Run speed (m/s)", 1.0, 5.0, 0.05, func(): return dog.speed, func(v): dog.speed = v)
	_row(box, "distance", "Camera distance", 1.0, 4.0, 0.05, func(): return rig.distance, func(v): rig.distance = v; rig.arm.spring_length = v)
	_row(box, "height", "Camera height", 0.3, 2.5, 0.05, func(): return rig.height, func(v): rig.height = v)
	_row(box, "yaw_follow", "Camera turn speed", 0.5, 6.0, 0.1, func(): return rig.yaw_follow, func(v): rig.yaw_follow = v)
	_load()

func _row(parent: Node, key: String, label: String, lo: float, hi: float, step: float, getter: Callable, setter: Callable) -> void:
	var h := HBoxContainer.new(); h.add_theme_constant_override("separation", 10)
	var l := Label.new(); l.text = label; l.custom_minimum_size.x = 170; l.add_theme_font_size_override("font_size", 14)
	var sl := HSlider.new(); sl.min_value = lo; sl.max_value = hi; sl.step = step; sl.custom_minimum_size.x = 170; sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sl.value = getter.call()
	var v := Label.new(); v.text = "%.2f" % sl.value; v.custom_minimum_size.x = 50; v.add_theme_font_size_override("font_size", 14)
	sl.value_changed.connect(func(x): setter.call(x); v.text = "%.2f" % x; _save())
	h.add_child(l); h.add_child(sl); h.add_child(v)
	parent.add_child(h)
	rows[key] = sl

func _save() -> void:
	var d := {}
	for k in rows: d[k] = rows[k].value
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(d))

func _load() -> void:
	if not FileAccess.file_exists(SAVE): return
	var f := FileAccess.open(SAVE, FileAccess.READ)
	if not f: return
	var d = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		for k in d:
			if rows.has(k): rows[k].value = d[k]
