extends Node

const RIG_SCENE: PackedScene = preload("res://scenes/combat/presentation/boss_presentation_rig.tscn")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var checks := 0
	var failures: Array[String] = []
	var rig: Control = RIG_SCENE.instantiate() as Control
	add_child(rig)
	await get_tree().process_frame

	if rig.get_node_or_null("WorldEffects") != null and rig.get_node_or_null("PhaseCue/AnimationPlayer") != null:
		checks += 1
		print("[boss-presentation] PASS authored rig contains separate world-effect and phase-cue layers")
	else:
		failures.append("Rig scene is missing an authored presentation layer.")

	var telegraph: Node2D = rig.call("show_target_telegraph", Vector2(240, 260), "elder_hollow", 0.42) as Node2D
	if telegraph != null and telegraph.get_node_or_null("AnimationPlayer") != null:
		checks += 1
		print("[boss-presentation] PASS target telegraph instantiates with authored AnimationPlayer")
	else:
		failures.append("Target telegraph scene did not instantiate its animation component.")
	if telegraph != null:
		var elder_style: Node2D = telegraph.get_node("Glyph/Artwork/ElderStyle")
		var matron_style: Node2D = telegraph.get_node("Glyph/Artwork/MatronStyle")
		if elder_style.visible and not matron_style.visible:
			checks += 1
			print("[boss-presentation] PASS Elder Hollow selects its root-pattern telegraph nodes")
		else:
			failures.append("Elder Hollow telegraph did not select its root-pattern nodes.")

	var telegraphs: Array = rig.call(
		"show_target_telegraphs",
		[Vector2(280, 400), Vector2(520, 420), Vector2(760, 390)],
		"fallen_matron",
		0.42
	)
	if telegraphs.size() == 3:
		checks += 1
		print("[boss-presentation] PASS multi-target warning creates one marker per target")
	else:
		failures.append("Multi-target warning did not create all target markers.")
	if telegraphs.size() == 3:
		var matron_style: Node2D = telegraphs[0].get_node("Glyph/Artwork/MatronStyle")
		var elder_style: Node2D = telegraphs[0].get_node("Glyph/Artwork/ElderStyle")
		if matron_style.visible and not elder_style.visible:
			checks += 1
			print("[boss-presentation] PASS Fallen Matron selects its floral telegraph nodes")
		else:
			failures.append("Fallen Matron telegraph did not select its floral nodes.")

	var matron_impact: Node2D = rig.call("play_impact", Vector2(900, 420), "fallen_matron", 1.0) as Node2D
	if matron_impact != null and matron_impact.get_node("Glyph/Artwork/MatronStyle").visible:
		checks += 1
		print("[boss-presentation] PASS Fallen Matron selects its floral impact nodes")
	else:
		failures.append("Fallen Matron impact did not select its floral nodes.")

	var elder_impact: Node2D = rig.call("play_impact", Vector2(1040, 420), "elder_hollow", 1.0) as Node2D
	if elder_impact != null and elder_impact.get_node("Glyph/Artwork/ElderStyle").visible:
		checks += 1
		print("[boss-presentation] PASS Elder Hollow selects its root-pattern impact nodes")
	else:
		failures.append("Elder Hollow impact did not select its root-pattern nodes.")

	var impact_events: Array = []
	var sequence_events: Array = []
	rig.connect("impact_spawned", func(at: Vector2, boss_id: String) -> void:
		impact_events.append({"at": at, "boss": boss_id})
	)
	rig.connect("multi_target_sequence_finished", func(boss_id: String, target_count: int) -> void:
		sequence_events.append({"boss": boss_id, "count": target_count})
	)
	rig.call(
		"play_multi_target_strike",
		[Vector2(300, 410), Vector2(540, 420), Vector2(780, 400)],
		"elder_hollow",
		0.18
	)
	await get_tree().create_timer(0.72).timeout
	if impact_events.size() == 3 and sequence_events.size() == 1 and int(sequence_events[0].count) == 3:
		checks += 1
		print("[boss-presentation] PASS multi-target sequence telegraphs and impacts all three positions")
	else:
		failures.append("Multi-target sequence did not present all impacts: %d impacts, %d completions." % [impact_events.size(), sequence_events.size()])

	var impact_count_before_cancel := impact_events.size()
	var sequence_count_before_cancel := sequence_events.size()
	rig.call("play_multi_target_strike", [Vector2(360, 430), Vector2(620, 430)], "elder_hollow", 0.45)
	rig.call("clear_transients")
	await get_tree().create_timer(0.52).timeout
	if impact_events.size() == impact_count_before_cancel and sequence_events.size() == sequence_count_before_cancel:
		checks += 1
		print("[boss-presentation] PASS clearing the rig cancels a pending multi-target sequence")
	else:
		failures.append("A cancelled multi-target sequence still emitted impacts or completion.")

	var phase_finished := [0]
	rig.connect("phase_change_finished", func() -> void:
		phase_finished[0] += 1
	)
	rig.call("show_phase_transition", "fallen_matron", 2)
	var phase_title := rig.get_node("PhaseCue/PhaseTitle") as Label
	if rig.get_node("PhaseCue").visible and phase_title.text.contains("THE GARDEN CLAIMS ITS DUE"):
		checks += 1
		print("[boss-presentation] PASS Fallen Matron phase cue uses its dedicated profile")
	else:
		failures.append("Fallen Matron phase cue did not display its profile title.")

	var phase_animation := rig.get_node("PhaseCue/AnimationPlayer") as AnimationPlayer
	if phase_animation.is_playing():
		phase_animation.advance(1.4)
	await get_tree().process_frame
	if not rig.get_node("PhaseCue").visible and phase_finished[0] == 1:
		checks += 1
		print("[boss-presentation] PASS Fallen Matron phase cue completes through AnimationPlayer")
	else:
		failures.append("Fallen Matron phase cue did not complete cleanly.")

	rig.call("show_phase_transition", "elder_hollow", 3)
	var elder_title := rig.get_node("PhaseCue/PhaseTitle") as Label
	if elder_title.text.contains("THE ROOTS AWAKEN"):
		checks += 1
		print("[boss-presentation] PASS Elder Hollow uses its distinct phase profile")
	else:
		failures.append("Elder Hollow phase cue did not use its dedicated profile.")
	phase_animation = rig.get_node("PhaseCue/AnimationPlayer") as AnimationPlayer
	if phase_animation.is_playing():
		phase_animation.advance(1.4)
	await get_tree().process_frame
	if not rig.get_node("PhaseCue").visible and phase_finished[0] == 2:
		checks += 1
		print("[boss-presentation] PASS Elder Hollow phase cue completes through AnimationPlayer")
	else:
		failures.append("Elder Hollow phase cue did not complete cleanly.")

	rig.call("clear_transients")
	await get_tree().process_frame
	if int(rig.call("transient_count")) == 0:
		checks += 1
		print("[boss-presentation] PASS transient presentation nodes can be cleared safely")
	else:
		failures.append("Transient presentation nodes remained after clear_transients().")

	if failures.is_empty():
		print("[boss-presentation] OK — %d passed, 0 failed." % checks)
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("[boss-presentation] " + failure)
		print("[boss-presentation] %d passed, %d failed." % [checks, failures.size()])
		get_tree().quit(1)
