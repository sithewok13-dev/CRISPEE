extends Node
## Turns keyboard, controller and touch into intents. Gameplay code asks
## this node what the player wants; it never reads devices directly.

const ACTIONS := ["action", "mark", "bark", "sniff"]

## Written by TouchControls.
var touch_move := Vector2.ZERO
var _touch_camera_drag := Vector2.ZERO
var _touch_presses: Dictionary = {}
var _mouse_drag := Vector2.ZERO

## True once a touch has been seen; the touch UI uses it to show itself.
var using_touch := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input_map()
	using_touch = DisplayServer.is_touchscreen_available()


func get_move() -> Vector2:
	var pad := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	return touch_move if touch_move.length() > pad.length() else pad


## Camera turn rate from sticks/keys, in -1..1 per axis.
func get_camera_rate() -> Vector2:
	return Input.get_vector("cam_left", "cam_right", "cam_up", "cam_down")


## Pixels dragged (touch or right mouse) since the last call.
func consume_camera_drag() -> Vector2:
	var d := _touch_camera_drag + _mouse_drag
	_touch_camera_drag = Vector2.ZERO
	_mouse_drag = Vector2.ZERO
	return d


## True once per press. Call from exactly one place per action.
func consume_pressed(action: String) -> bool:
	if _touch_presses.get(action, false):
		_touch_presses[action] = false
		return true
	return Input.is_action_just_pressed(action)


func add_touch_camera_drag(delta: Vector2) -> void:
	_touch_camera_drag += delta


func press_touch(action: String) -> void:
	_touch_presses[action] = true


func clear() -> void:
	touch_move = Vector2.ZERO
	_touch_camera_drag = Vector2.ZERO
	_mouse_drag = Vector2.ZERO
	_touch_presses.clear()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_RIGHT):
		_mouse_drag += event.relative
	elif event is InputEventScreenTouch:
		using_touch = true


func _setup_input_map() -> void:
	_bind("move_forward", [KEY_W], [], [[JOY_AXIS_LEFT_Y, -1.0]])
	_bind("move_back", [KEY_S], [], [[JOY_AXIS_LEFT_Y, 1.0]])
	_bind("move_left", [KEY_A], [], [[JOY_AXIS_LEFT_X, -1.0]])
	_bind("move_right", [KEY_D], [], [[JOY_AXIS_LEFT_X, 1.0]])
	_bind("cam_left", [KEY_LEFT], [], [[JOY_AXIS_RIGHT_X, -1.0]])
	_bind("cam_right", [KEY_RIGHT], [], [[JOY_AXIS_RIGHT_X, 1.0]])
	_bind("cam_up", [KEY_UP], [], [[JOY_AXIS_RIGHT_Y, -1.0]])
	_bind("cam_down", [KEY_DOWN], [], [[JOY_AXIS_RIGHT_Y, 1.0]])
	_bind("action", [KEY_SPACE, KEY_ENTER], [JOY_BUTTON_A], [])
	_bind("mark", [KEY_E], [JOY_BUTTON_B], [])
	_bind("sniff", [KEY_R], [JOY_BUTTON_X], [])
	_bind("bark", [KEY_F], [JOY_BUTTON_Y], [])
	_bind("pause", [KEY_ESCAPE], [JOY_BUTTON_START], [])


func _bind(action: String, keys: Array, buttons: Array, axes: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)
	for b in buttons:
		var e := InputEventJoypadButton.new()
		e.button_index = b
		InputMap.action_add_event(action, e)
	for a in axes:
		var e := InputEventJoypadMotion.new()
		e.axis = a[0]
		e.axis_value = a[1]
		InputMap.action_add_event(action, e)
