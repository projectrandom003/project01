extends SceneTree

func _fail(msg: String) -> void:
	printerr("[VERIFY] FAIL: " + msg)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var scene := load("res://scenes/ui/components/pause_party_member.tscn") as PackedScene
	if scene == null:
		_fail("could not load pause_party_member.tscn")
		quit(1)
		return
	var member := scene.instantiate() as VBoxContainer
	if member == null:
		_fail("root is not a VBoxContainer")
		ok = false
	var portrait := member.get_node_or_null("Portrait")
	var name_label := member.get_node_or_null("Name") as Label
	var level_label := member.get_node_or_null("Level") as Label
	if portrait == null or name_label == null or level_label == null:
		_fail("missing expected child nodes Portrait/Name/Level")
		ok = false
	else:
		if (member as Control).custom_minimum_size != Vector2(92, 0):
			_fail("member custom_minimum_size mismatch")
			ok = false
		if (portrait as Control).custom_minimum_size != Vector2(82, 86):
			_fail("portrait custom_minimum_size mismatch")
			ok = false
		if name_label.horizontal_alignment != HORIZONTAL_ALIGNMENT_CENTER:
			_fail("name alignment mismatch")
			ok = false
		if level_label.horizontal_alignment != HORIZONTAL_ALIGNMENT_CENTER:
			_fail("level alignment mismatch")
			ok = false
	# smoke setup path without requiring autoload data
	if member.has_method("setup"):
		member.setup(null, 7)
		if str((member.get_node("Level") as Label).text) != "Lv. 7":
			_fail("level text not populated by setup")
			ok = false
		if str((member.get_node("Name") as Label).text) != "Unknown":
			_fail("fallback name not populated by setup")
			ok = false
	if ok:
		print("[VERIFY] PASS: pause party member scene structure and setup")
		quit(0)
	else:
		quit(1)
