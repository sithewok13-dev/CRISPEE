extends CanvasLayer
## Pee Vision: the world goes yellow for a few seconds, spots glow through walls,
## a low drone swells in and reverses out.

@export var duration := 6.0
@export var cooldown := 4.0
var active := false
var cooldown_left := 0.0
var _t := 0.0
var rect: ColorRect
var mat: ShaderMaterial
var player: AudioStreamPlayer
var _gen: AudioStreamGeneratorPlayback
var _phase := 0.0
var _phase2 := 0.0
var _vol := 0.0

func _ready() -> void:
	layer = 5
	rect = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/pee_vision.gdshader")
	mat.set_shader_parameter("strength", 0.0)
	rect.material = mat
	rect.visible = false
	add_child(rect)
	player = AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new(); gen.mix_rate = 22050; gen.buffer_length = 0.2
	player.stream = gen
	player.volume_db = -6
	add_child(player)

func can_activate() -> bool:
	return not active and cooldown_left <= 0.0

func activate() -> bool:
	if not can_activate():
		return false
	active = true; _t = 0.0
	rect.visible = true
	for s in Game.spots: s.set_vision(true)
	player.play()
	_gen = player.get_stream_playback()
	return true

func _process(delta: float) -> void:
	if cooldown_left > 0.0: cooldown_left -= delta
	if not active:
		return
	_t += delta
	var k := 1.0
	if _t < 0.35: k = _t / 0.35
	elif _t > duration - 0.6: k = max(0.0, (duration - _t) / 0.6)
	mat.set_shader_parameter("strength", k)
	_vol = k
	_fill_audio()
	if _t >= duration:
		active = false
		rect.visible = false
		for s in Game.spots: s.set_vision(false)
		player.stop()
		cooldown_left = cooldown

func _fill_audio() -> void:
	if _gen == null: return
	var frames := _gen.get_frames_available()
	var rate := 22050.0
	var f1 := 55.0; var f2 := 82.5 * (1.0 + 0.004 * sin(_t * 0.7))
	var swell := 0.5 + 0.5 * sin(_t * 1.3)
	for i in range(frames):
		_phase += TAU * f1 / rate; _phase2 += TAU * f2 / rate
		var s := 0.5 * sin(_phase) + 0.3 * sin(_phase2) + 0.15 * sin(_phase * 2.01) * swell
		var v := s * _vol * 0.6
		_gen.push_frame(Vector2(v, v))
