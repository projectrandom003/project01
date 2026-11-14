extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/characters/actor_visual.tscn") as PackedScene
	if packed == null:
		push_error("Could not load ActorVisual scene")
		quit(1)
		return
	var actor := packed.instantiate() as ActorVisual
	root.add_child(actor)
	await process_frame
	actor.configure_character("gerald")
	var fx := actor.get_node_or_null("Effects/GeraldCombatFX") as GeraldCombatEffects
	if fx == null:
		push_error("Gerald combat effects node is missing")
		quit(1)
		return
	for node_name in ["SlashSparks", "ImpactSparks", "CastEmbers", "VoidArc", "VoidHalo", "VoidMotes"]:
		if fx.get_node_or_null(node_name) == null:
			push_error("Missing node-authored Gerald particle system: " + node_name)
			quit(1)
			return
	var attacks := ["slash_combo", "heavy_strike", "spinning_cleave"]
	var impact_frames := [3, 4, 5]
	for index in attacks.size():
		actor.animator.play_forced(CharacterAnimator.State.IDLE)
		await process_frame
		var variant: String = attacks[index]
		actor.play_attack(variant)
		await process_frame
		if not fx.visible or not fx.get_node("SlashTrail").visible or not fx.get_node("VoidArc").visible:
			push_error("Flame/Void attack FX did not activate for " + variant)
			quit(1)
			return
		if fx.attack_variant != variant:
			push_error("Attack variant was not retained: " + variant)
			quit(1)
			return
		if not (fx.get_node("SlashSparks") as CPUParticles2D).emitting:
			push_error("Slash ember particles did not emit for " + variant)
			quit(1)
			return
		actor.animator.frame = int(impact_frames[index])
		await process_frame
		if not (fx.get_node("ImpactSparks") as CPUParticles2D).emitting:
			push_error("Impact sparks did not synchronize for " + variant)
			quit(1)
			return
	var skills := ["blade_wave", "ground_eruption", "guardian_aura"]
	for variant in skills:
		actor.animator.play_forced(CharacterAnimator.State.IDLE)
		await process_frame
		actor.play_skill(variant)
		await process_frame
		if not fx.visible or fx.skill_variant != variant:
			push_error("Skill FX did not activate for " + variant)
			quit(1)
			return
		if variant == "guardian_aura":
			if not fx.get_node("AuraHalo").visible or not fx.get_node("VoidHalo").visible:
				push_error("Guardian Aura's paired Flame/Void halos did not activate")
				quit(1)
				return
			if not (fx.get_node("VoidMotes") as CPUParticles2D).emitting:
				push_error("Guardian Aura's Void motes did not emit")
				quit(1)
				return
		else:
			if variant == "ground_eruption" and not fx.get_node("EruptionCenter").visible:
				push_error("Ground Eruption spikes did not activate")
				quit(1)
				return
			if variant == "blade_wave" and not fx.get_node("CastRing").visible:
				push_error("Blade Wave arc did not activate")
				quit(1)
				return
			actor.animator.frame = 5
			await process_frame
			if not (fx.get_node("CastEmbers") as CPUParticles2D).emitting:
				push_error("Cast embers did not fire on release for " + variant)
				quit(1)
				return
	actor.animator.play_forced(CharacterAnimator.State.IDLE)
	await create_timer(1.35).timeout
	if fx.visible:
		push_error("Gerald combat FX did not hide in IDLE")
		quit(1)
		return
	print("GERALD_COMBAT_FX_VERIFY_OK attacks=3 skills=3 node_particles=4 flame_void_duality=PASS synchronized_impacts=PASS idle_cleanup=PASS")
	quit(0)
