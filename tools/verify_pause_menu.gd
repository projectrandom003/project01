extends Node

var requested_screen := ""

func _ready() -> void:
	var menu := PauseMenu.new()
	menu.size = Vector2(1280, 720)
	add_child(menu)
	await get_tree().process_frame
	var required := ["Character Roster", "Inventory", "Summon", "Quest Log", "World Map"]
	var found: Array[String] = []
	var buttons: Array[Node] = []
	_collect_buttons(menu, buttons)
	for button in buttons:
		for label in required:
			if str(button.text).begins_with(label):
				found.append(label)
	for label in required:
		if not found.has(label):
			push_error("[pause-menu] Missing navigation: " + label)
			get_tree().quit(1)
			return
	requested_screen = ""
	menu.navigate_requested.connect(_on_navigation_requested)
	for button in buttons:
		if str(button.text).begins_with("World Map"):
			button.pressed.emit()
			break
	if requested_screen != "map":
		push_error("[pause-menu] World Map navigation did not emit map.")
		get_tree().quit(1)
		return
	print("[pause-menu] OK — five navigation destinations and World Map signal.")
	get_tree().quit(0)

func _on_navigation_requested(screen_id: String) -> void:
	requested_screen = screen_id


func _collect_buttons(node: Node, output: Array[Node]) -> void:
	for child in node.get_children():
		if child is Button:
			output.append(child)
		_collect_buttons(child, output)
