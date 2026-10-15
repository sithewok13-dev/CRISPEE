class_name Main
extends Node3D
## Composes the first playable: room, Crispee, camera, human, puzzle, UI.
## Each piece only knows the interfaces it is handed here.

## Set before (re)loading to skip the title menu.
static var skip_title := false

var level: LivingRoom
var player: Crispee
var rig: CameraRig
var puzzle: DeliveryPuzzle
var hud: Hud
var touch: TouchControls


func _ready() -> void:
	Engine.max_fps = 60
	level = LivingRoom.new()
	level.name = "LivingRoom"
	add_child(level)

	player = Crispee.new()
	player.name = "Crispee"
	level.add_child(player)
	player.drop_parent = level

	rig = CameraRig.new()
	rig.name = "CameraRig"
	add_child(rig)
	rig.target = player
	player.camera_yaw_provider = rig.get_yaw
	level.add_camera_zones(rig)

	puzzle = DeliveryPuzzle.new()
	puzzle.name = "DeliveryPuzzle"
	add_child(puzzle)
	puzzle.setup(level, player, level.human)

	var touch_layer := CanvasLayer.new()
	touch_layer.layer = 5
	add_child(touch_layer)
	touch = TouchControls.new()
	touch_layer.add_child(touch)
	player.context_changed.connect(touch.set_action_label)
	player.mark_hint_changed.connect(touch.set_mark_hint)

	hud = Hud.new()
	add_child(hud)
	hud.objective_provider = puzzle.objective_hint
	touch.pause_pressed.connect(hud.open_pause)
	hud.new_game_requested.connect(restart)
	hud.continue_requested.connect(continue_game)
	GameEvents.slice_completed.connect(hud.show_end)
	WorldState.player_position_provider = func() -> Vector3: return player.global_position

	_place_player(LivingRoom.SPAWN, 0.0)
	if skip_title:
		skip_title = false
		start_new_game()
	else:
		hud.show_title(WorldState.has_save())


func start_new_game() -> void:
	WorldState.reset()
	WorldState.delete_save()
	_place_player(LivingRoom.SPAWN, 0.0)
	get_tree().paused = false


func continue_game() -> void:
	if WorldState.load_game():
		puzzle.apply_state()
		if WorldState.has_checkpoint:
			_place_player(WorldState.checkpoint_position, player.rotation.y)
	get_tree().paused = false


## New game from anywhere: reload the scene so every system starts clean.
func restart() -> void:
	WorldState.reset()
	WorldState.delete_save()
	InputRouter.clear()
	skip_title = true
	get_tree().paused = false
	get_tree().reload_current_scene()


func _place_player(pos: Vector3, yaw: float) -> void:
	player.teleport(pos, yaw)
	rig.snap_behind()
