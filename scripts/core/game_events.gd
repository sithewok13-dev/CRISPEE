extends Node
## Global signal bus. Systems announce what happened here; reactions (NPCs,
## puzzles, UI) listen. Nothing in here holds state.

## Crispee marked something. `target` is an Interactable for special claims,
## or null for an ordinary mark; `surface_name` describes what got marked.
signal marked(target: Node, surface_name: String, position: Vector3)
signal barked(position: Vector3)
signal sniffed(position: Vector3)
signal item_picked_up(item: Node)
signal item_dropped(item: Node)
signal item_given(item: Node, receiver: Node)
## Something wants a line on screen. `speaker` is "" for Crispee's own
## (wordless) impressions, which are shown in brackets.
signal caption(text: String, speaker: String, duration: float)
signal flag_changed(flag: String, value: Variant)
signal slice_completed


func say(text: String, speaker: String = "", duration: float = 3.0) -> void:
	caption.emit(text, speaker, duration)
