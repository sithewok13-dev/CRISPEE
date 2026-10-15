extends Node
## Placeholder sound effects synthesized at startup so the greybox has
## feedback without any audio assets. Replace with recordings of the real
## Crispee (barks, nails on floor, jingles) when they exist.

const RATE := 22050

var sounds: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	sounds["bark"] = _bark()
	sounds["squeak"] = _tone(0.16, 1800.0, 2600.0, 0.0, 0.5)
	sounds["hop"] = _tone(0.07, 380.0, 220.0, 0.25, 0.35)
	sounds["land"] = _tone(0.06, 160.0, 90.0, 0.6, 0.4)
	sounds["trickle"] = _trickle()
	sounds["empty"] = _tone(0.25, 300.0, 180.0, 0.05, 0.2)
	sounds["claim"] = _chime()
	sounds["door"] = _tone(0.5, 140.0, 95.0, 0.15, 0.35)
	sounds["pickup"] = _tone(0.05, 700.0, 900.0, 0.1, 0.3)
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func play(sound: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not sounds.has(sound):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = sounds[sound]
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


func _make(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav


func _tone(length: float, f0: float, f1: float, noise: float, gain: float) -> AudioStreamWAV:
	var n := int(length * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / n
		phase += TAU * lerpf(f0, f1, t) / RATE
		var env := minf(t * 30.0, 1.0) * pow(1.0 - t, 2.0)
		s[i] = (sin(phase) * (1.0 - noise) + randf_range(-1, 1) * noise) * env * gain
	return _make(s)


## Two quick, slightly nasal yips: small dog, big opinions.
func _bark() -> AudioStreamWAV:
	var n := int(0.32 * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var local := fmod(t, 0.16) / 0.16
		var f := lerpf(950.0, 520.0, local)
		phase += TAU * f / RATE
		var env := minf(local * 25.0, 1.0) * pow(1.0 - local, 3.0)
		var v := sin(phase) + 0.5 * sin(phase * 2.0) + 0.3 * sin(phase * 3.0)
		s[i] = (v * 0.42 + randf_range(-1, 1) * 0.12) * env
	return _make(s)


func _trickle() -> AudioStreamWAV:
	var n := int(1.0 * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / n
		lp = lerpf(lp, randf_range(-1, 1), 0.35)
		var env := minf(t * 8.0, 1.0) * minf((1.0 - t) * 6.0, 1.0)
		s[i] = lp * env * 0.35 * (0.8 + 0.2 * sin(t * 90.0))
	return _make(s)


func _chime() -> AudioStreamWAV:
	var n := int(0.6 * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / RATE
		var env := exp(-t * 6.0)
		var f := 660.0 if t < 0.12 else 990.0
		s[i] = sin(TAU * f * t) * env * 0.3
	return _make(s)
