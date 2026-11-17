extends SceneTree

func _fail(msg: String) -> void:
	printerr("[VERIFY] FAIL: " + msg)

func _check_full_rect(ctrl: Control, label: String) -> bool:
	var ok := true
	if ctrl.anchor_left != 0.0 or ctrl.anchor_top != 0.0:
		_fail(label + " anchor_left/top expected 0,0 got %s,%s" % [ctrl.anchor_left, ctrl.anchor_top])
		ok = false
	if ctrl.anchor_right != 1.0 or ctrl.anchor_bottom != 1.0:
		_fail(label + " anchor_right/bottom expected 1,1 got %s,%s" % [ctrl.anchor_right, ctrl.anchor_bottom])
		ok = false
	if ctrl.grow_horizontal != Control.GROW_DIRECTION_BOTH or ctrl.grow_vertical != Control.GROW_DIRECTION_BOTH:
		_fail(label + " grow expected BOTH,BOTH got %s,%s" % [ctrl.grow_horizontal, ctrl.grow_vertical])
		ok = false
	return ok

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var results_scene := load("res://scenes/ui/components/summon_results_overlay.tscn") as PackedScene
	var reveal_scene := load("res://scenes/ui/components/summon_reveal_overlay.tscn") as PackedScene
	if results_scene == null:
		_fail("could not load summon_results_overlay.tscn")
		quit(1); return
	if reveal_scene == null:
		_fail("could not load summon_reveal_overlay.tscn")
		quit(1); return
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.size = Vector2(1280, 720)
	get_root().add_child(root)

	var results := results_scene.instantiate() as Control
	root.add_child(results)
	ok = _check_full_rect(results, "SummonResultsOverlay root") and ok
	var dim := results.get_node_or_null("Dim") as Control
	var center := results.get_node_or_null("Center") as Control
	var panel := results.get_node_or_null("Center/Panel") as Control
	if dim == null or center == null or panel == null:
		_fail("SummonResultsOverlay missing expected children")
		ok = false

	var reveal := reveal_scene.instantiate() as Control
	root.add_child(reveal)
	ok = _check_full_rect(reveal, "SummonRevealOverlay root") and ok

	await process_frame
	# sanity: in a 1280x720 root, full-rect overlay should span root rect
	var rr := results.get_rect()
	if rr.size.x < 1279.0 or rr.size.y < 719.0:
		_fail("SummonResultsOverlay rect too small in 1280x720 root: %s" % rr)
		ok = false
	root.size = Vector2(1920, 1080)
	await process_frame
	rr = results.get_rect()
	if rr.size.x < 1919.0 or rr.size.y < 1079.0:
		_fail("SummonResultsOverlay rect too small in 1920x1080 root: %s" % rr)
		ok = false

	if ok:
		print("[VERIFY] PASS: summon overlays are full-rect and resize with parent (1280x720, 1920x1080)")
		quit(0)
	else:
		quit(1)
