extends CanvasLayer
## Claim list, timer, bladder, prompt, toast, level complete.

var territory: Label
var count: Label
var list: Label
var timer: Label
var bladder: ProgressBar
var bladder_lbl: Label
var prompt: Label
var toast: PanelContainer
var toast_lbl: Label
var done: PanelContainer
var done_lbl: Label
var vision_lbl: Label
var _toast_t := 0.0

func _ready() -> void:
	layer = 10
	var root := Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT); root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var top := VBoxContainer.new(); top.position = Vector2(36, 24); top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)
	territory = _label(top, 14, Color(1, 1, 1, 0.85))
	count = _label(top, 28, Color.WHITE)
	list = _label(top, 17, Color(1, 1, 1, 0.95))
	timer = _label(root, 24, Color.WHITE)
	_anchor(timer, 0.5, 0.0, -100, 22, 200, 36)
	timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var br := HBoxContainer.new(); br.set_anchors_preset(Control.PRESET_TOP_RIGHT); br.position = Vector2(-240, 28); br.size = Vector2(204, 20)
	br.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(br)
	bladder_lbl = _label(br, 14, Color.WHITE); bladder_lbl.text = "BLADDER  "
	bladder = ProgressBar.new(); bladder.custom_minimum_size = Vector2(130, 18); bladder.show_percentage = false
	bladder.max_value = 3; bladder.value = 3
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.97, 0.83, 0.29); sb.set_corner_radius_all(6)
	bladder.add_theme_stylebox_override("fill", sb)
	var sbb := StyleBoxFlat.new(); sbb.bg_color = Color(0, 0, 0, 0.45); sbb.set_corner_radius_all(6); sbb.set_border_width_all(2); sbb.border_color = Color(1, 1, 1, 0.7)
	bladder.add_theme_stylebox_override("background", sbb)
	br.add_child(bladder)
	prompt = _label(root, 20, Color(1, 0.89, 0.42)); _anchor(prompt, 0.5, 0.5, -250, 80, 500, 34)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vision_lbl = _label(root, 16, Color(1, 0.89, 0.42)); _anchor(vision_lbl, 0.5, 0.0, -200, 62, 400, 24)
	vision_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vision_lbl.visible = false
	toast = PanelContainer.new(); _anchor(toast, 0.5, 1.0, -320, -130, 640, 70)
	var ts := StyleBoxFlat.new(); ts.bg_color = Color(0, 0, 0, 0.66); ts.set_corner_radius_all(12); ts.set_border_width_all(2); ts.border_color = Color(1, 1, 1, 0.5); ts.content_margin_left = 18; ts.content_margin_right = 18; ts.content_margin_top = 10; ts.content_margin_bottom = 10
	toast.add_theme_stylebox_override("panel", ts)
	toast_lbl = _label(toast, 18, Color.WHITE); toast_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.visible = false
	root.add_child(toast)
	done = PanelContainer.new(); _anchor(done, 0.5, 0.5, -260, -110, 520, 220)
	done.add_theme_stylebox_override("panel", ts)
	done_lbl = _label(done, 22, Color.WHITE); done_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; done_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	done.visible = false
	root.add_child(done)
	Game.claimed.connect(func(_s): refresh())
	Game.bladder_changed.connect(func(m, mx): bladder.max_value = mx; bladder.value = m)
	Game.level_finished.connect(_on_finished)

func _anchor(c: Control, ax: float, ay: float, x: float, y: float, w: float, h: float) -> void:
	c.anchor_left = ax; c.anchor_right = ax; c.anchor_top = ay; c.anchor_bottom = ay
	c.offset_left = x; c.offset_top = y; c.offset_right = x + w; c.offset_bottom = y + h

func _label(parent: Node, size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("shadow_offset_y", 1)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func refresh() -> void:
	territory.text = "TERRITORY 1 · " + Game.territory_name.to_upper()
	count.text = "%d / %d claimed   (par %d)" % [Game.owned_count(), Game.spots.size(), Game.par]
	var lines := []
	for s in Game.spots:
		lines.append(("✓ " if s.is_owned() else "○ ") + s.label)
	list.text = "\n".join(lines)
	bladder.max_value = Game.max_marks; bladder.value = Game.marks

func _process(delta: float) -> void:
	timer.text = Game.fmt_time(Game.time_sec)
	if _toast_t > 0.0:
		_toast_t -= delta
		if _toast_t <= 0.0: toast.visible = false

func set_prompt(text: String) -> void:
	prompt.text = text

func show_toast(text: String, seconds := 4.5) -> void:
	toast_lbl.text = text
	toast.visible = true
	_toast_t = seconds

func set_vision(on: bool) -> void:
	vision_lbl.visible = on
	vision_lbl.text = "PEE VISION" if on else ""

func _on_finished(t: float) -> void:
	var best := Game.best_time()
	done_lbl.text = "The living room is Crispee's.\n\nTime %s\nBest %s\n%d of %d claimed" % [Game.fmt_time(t), Game.fmt_time(best), Game.owned_count(), Game.spots.size()]
	done.visible = true
