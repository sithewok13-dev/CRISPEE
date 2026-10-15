class_name Hud
extends CanvasLayer
## Captions, claim count, performance overlay and menus (title, pause, end).
## Built in code for the greybox; real UI art comes later.

signal new_game_requested
signal continue_requested

## Returns the current objective text for the pause menu.
var objective_provider: Callable

var _root: Control
var _caption_panel: PanelContainer
var _caption: Label
var _caption_time := 0.0
var _perf: Button
var _perf_detail := false
var _perf_timer := 0.0
var _claims: Label
var _title: Control
var _continue_button: Button
var _pause: Control
var _pause_hint: Label
var _fps_button: Button
var _end: Control


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	theme.default_font_size = 26
	_root.theme = theme
	add_child(_root)
	_build_overlay()
	_title = _build_title()
	_pause = _build_pause()
	_end = _build_end()
	for menu in [_title, _pause, _end]:
		menu.visible = false
	GameEvents.caption.connect(_on_caption)


func show_title(has_save: bool) -> void:
	_continue_button.visible = has_save
	_title.visible = true
	get_tree().paused = true


func open_pause() -> void:
	if _title.visible or _end.visible:
		return
	_pause_hint.text = objective_provider.call() if objective_provider.is_valid() else ""
	_pause.visible = true
	get_tree().paused = true


func close_menus() -> void:
	_title.visible = false
	_pause.visible = false
	_end.visible = false
	get_tree().paused = false


func show_end() -> void:
	_end.visible = true
	_end.modulate.a = 0.0
	create_tween().tween_property(_end, "modulate:a", 1.0, 1.2)
	get_tree().paused = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if _pause.visible:
			close_menus()
		else:
			open_pause()


func _process(delta: float) -> void:
	if _caption_time > 0.0:
		_caption_time -= delta
		if _caption_time <= 0.0:
			create_tween().tween_property(_caption_panel, "modulate:a", 0.0, 0.35)
	_perf_timer -= delta
	if _perf_timer <= 0.0:
		_perf_timer = 0.5
		_update_perf()
	_claims.text = "Territory: %d claimed · %d marks" % [WorldState.claims.size(), WorldState.ordinary_marks]


func _on_caption(text: String, speaker: String, duration: float) -> void:
	if speaker == "":
		_caption.text = text
		_caption.add_theme_color_override("font_color", Color(1.0, 0.86, 0.55))
	else:
		_caption.text = "%s: “%s”" % [speaker, text]
		_caption.add_theme_color_override("font_color", Color(1, 1, 1))
	_caption_time = duration
	_caption_panel.modulate.a = 1.0


func _update_perf() -> void:
	var fps := Engine.get_frames_per_second()
	var ms := 1000.0 / maxf(fps, 1.0)
	var text := "%d fps · %.1f ms" % [fps, ms]
	if _perf_detail:
		text += "\ncpu %.1f ms · draws %d · prims %dk · mem %d MB" % [
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000,
			Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576,
		]
	_perf.text = text


func _on_continue() -> void:
	close_menus()
	continue_requested.emit()


func _on_new_game() -> void:
	close_menus()
	new_game_requested.emit()


func _toggle_fps() -> void:
	Engine.max_fps = 30 if Engine.max_fps == 60 else 60
	_fps_button.text = "Frame cap: %d" % Engine.max_fps


func _toggle_perf_detail() -> void:
	_perf_detail = not _perf_detail


# --- Construction ---------------------------------------------------------------

func _build_overlay() -> void:
	_perf = Button.new()
	_perf.flat = true
	_perf.add_theme_font_size_override("font_size", 16)
	_perf.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_perf.position = Vector2(28, 8)
	_perf.pressed.connect(_toggle_perf_detail)
	_root.add_child(_perf)

	_claims = Label.new()
	_claims.add_theme_font_size_override("font_size", 18)
	_claims.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	_claims.position = Vector2(34, 62)
	_root.add_child(_claims)

	_caption_panel = PanelContainer.new()
	_caption_panel.anchor_left = 0.5
	_caption_panel.anchor_right = 0.5
	_caption_panel.offset_left = -360.0
	_caption_panel.offset_right = 360.0
	_caption_panel.offset_top = 24.0
	_caption_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_caption_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.5)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(14)
	_caption_panel.add_theme_stylebox_override("panel", style)
	_caption = Label.new()
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption_panel.add_child(_caption)
	_caption_panel.modulate.a = 0.0
	_root.add_child(_caption_panel)


func _menu(title: String, title_size: int) -> VBoxContainer:
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.03, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(box)
	var label := Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", title_size)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	box.add_child(label)
	return box


func _text(box: Container, text: String, size: int = 22, alpha: float = 0.8) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(1, 1, 1, alpha))
	box.add_child(l)
	return l


func _button(box: Container, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(380, 70)
	b.pressed.connect(action)
	box.add_child(b)
	return b


func _build_title() -> Control:
	var box := _menu("CRISPEE", 84)
	_text(box, "First playable · greybox 0.1 · placeholder art")
	_text(box, "Left thumb: move   ·   right thumb: look   ·   Hop/Grab/Give, Mark, Sniff, Bark", 18, 0.6)
	_continue_button = _button(box, "Continue", _on_continue)
	_button(box, "New game", _on_new_game)
	return box.get_parent().get_parent()


func _build_pause() -> Control:
	var box := _menu("Paused", 56)
	_pause_hint = _text(box, "", 22, 0.85)
	_button(box, "Resume", close_menus)
	_fps_button = _button(box, "Frame cap: 60", _toggle_fps)
	_button(box, "Restart from the couch", _on_new_game)
	return box.get_parent().get_parent()


func _build_end() -> Control:
	var box := _menu("CRISPEE", 96)
	_text(box, "End of the first playable.", 28, 0.95)
	_text(box, "The neighbourhood has been notified.", 22, 0.7)
	_button(box, "Play again", _on_new_game)
	return box.get_parent().get_parent()
