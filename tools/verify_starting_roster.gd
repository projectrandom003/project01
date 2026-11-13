extends Node
## Verifies the new starting party, portrait fallback, legacy-save migration and
## combat setup.
##
## Run with:
##   godot --headless --path . res://tools/verify_starting_roster.tscn
##
## The tool snapshots the local save, runs in-memory checks, then restores the
## snapshot. Exits 0 when every check passes, 1 otherwise.

var _failures: int = 0


func _ready() -> void:
	var had_save := FileAccess.file_exists(SaveService.SAVE_PATH)
	var save_snapshot := ""
	if had_save:
		save_snapshot = FileAccess.get_file_as_string(SaveService.SAVE_PATH)

	_check_new_game()
	_check_portraits()
	_check_legacy_save_migration()
	_check_save_round_trip()
	_check_combat()

	if had_save:
		var file := FileAccess.open(SaveService.SAVE_PATH, FileAccess.WRITE)
		if file != null:
			file.store_string(save_snapshot)
			file.close()
	else:
		SaveService.delete_save()

	print("[roster] %s" % ("OK" if _failures == 0 else "FAILED (%d)" % _failures))
	get_tree().quit(0 if _failures == 0 else 1)


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("[roster] PASS " + label)
	else:
		_failures += 1
		printerr("[roster] FAIL " + label + ("" if detail.is_empty() else " - " + detail))


func _roster_ids() -> Array:
	var out: Array = []
	for instance in GameState.roster:
		out.append(instance.char_id)
	return out


func _party_ids() -> Array:
	var out: Array = []
	for instance in GameState.party_instances():
		out.append(instance.char_id)
	return out


func _check_new_game() -> void:
	GameState.new_game("Roster Verify")
	_check("new_game grants exactly 3 characters", GameState.roster.size() == 3, str(GameState.roster.size()))
	_check("new_game fills exactly 3 party slots", GameState.party.size() == 3, str(GameState.party.size()))
	_check("starting roster is gerald, lilith, kael", _roster_ids() == ["gerald", "lilith", "kael"], str(_roster_ids()))
	_check("initial party is gerald, lilith, kael", _party_ids() == ["gerald", "lilith", "kael"], str(_party_ids()))
	_check("gerald resolves in ContentDB", ContentDB.get_character("gerald") != null)
	_check("lilith resolves in ContentDB", ContentDB.get_character("lilith") != null)
	_check("kael resolves in ContentDB", ContentDB.get_character("kael") != null)
	_check("removed starters are not owned", not GameState.owns_character("mira_sol") and not GameState.owns_character("bramble"))
	_check("main menu starter cards match the party", MainMenu.STARTERS == ["gerald", "lilith", "kael"], str(MainMenu.STARTERS))
	_check("MainCharacterRoster sees gerald in ContentDB", MainCharacterRoster.is_in_content_db("gerald"))
	_check("MainCharacterRoster sees lilith in ContentDB", MainCharacterRoster.is_in_content_db("lilith"))


func _check_portraits() -> void:
	# Gerald, Lilith and Kael all ship final art now, so their real portraits
	# must be picked up and the procedural fallback must stay inactive.
	for character_id in ["gerald", "lilith", "kael"]:
		var definition := ContentDB.get_character(character_id)
		var view := PortraitView.new()
		view.setup_character(definition)
		var report := view.portrait_report()
		_check("final portrait used: " + character_id,
			not bool(report.get("fallback_active", true)), str(report))
		view.free()
		_check("portrait texture loads: " + character_id,
			MainCharacterRoster.portrait_texture(character_id) != null)
		_check("portrait status is portrait_ready: " + character_id,
			MainCharacterRoster.asset_status(character_id) == "portrait_ready",
			MainCharacterRoster.asset_status(character_id))
		_check("world sheet exposes 72 animations: " + character_id,
			MainCharacterRoster.world_sheet(character_id) != null
			and MainCharacterRoster.world_sheet(character_id).get_animation_names().size() == 72)
		_check("world art is runtime-ready: " + character_id,
			MainCharacterRoster.world_art_ready(character_id))
		_check("combat sprite loads: " + character_id,
			MainCharacterRoster._texture_ready(MainCharacterRoster.combat_sprite_path(character_id)))
		_check("full-body art loads: " + character_id,
			MainCharacterRoster._texture_ready(MainCharacterRoster.full_body_path(character_id)))
		_check("art status is final: " + character_id,
			MainCharacterRoster.art_status(character_id) == "final",
			MainCharacterRoster.art_status(character_id))


func _legacy_save() -> Dictionary:
	var mira := CharacterInstance.create("mira_sol", "legacy_mira")
	mira.equipment = { "weapon": "gladewood_bow" }
	var kael := CharacterInstance.create("kael", "legacy_kael")
	var bramble := CharacterInstance.create("bramble", "legacy_bramble")
	bramble.equipment = { "armor": "mossweave_vest" }
	return {
		"profile": { "name": "Legacy", "level": 1, "gold": 0, "crystals": 0 },
		"roster": [mira.to_dict(), kael.to_dict(), bramble.to_dict()],
		"party": ["legacy_mira", "legacy_kael", "legacy_bramble"],
		"inventory": {},
		"quests": {},
		"pity": {},
		"flags": {},
		"position": { "x": 0.0, "y": 0.0 },
		"has_position": false,
	}


func _check_legacy_save_migration() -> void:
	GameState._load_from_dict(_legacy_save())
	_check("migration removes mira_sol", not GameState.owns_character("mira_sol"))
	_check("migration removes bramble", not GameState.owns_character("bramble"))
	_check("migration adds gerald", GameState.owns_character("gerald"))
	_check("migration adds lilith", GameState.owns_character("lilith"))
	_check("migration keeps kael", GameState.owns_character("kael"))
	_check("migrated roster is exactly the 3 starters", GameState.roster.size() == 3, str(GameState.roster.size()))
	_check("migrated party is exactly the 3 starters", _party_ids() == ["gerald", "lilith", "kael"], str(_party_ids()))
	_check("equipped weapon was refunded", GameState.item_count("gladewood_bow") == 1, str(GameState.item_count("gladewood_bow")))
	_check("equipped armor was refunded", GameState.item_count("mossweave_vest") == 1, str(GameState.item_count("mossweave_vest")))


func _check_save_round_trip() -> void:
	GameState.new_game("Round Trip")
	GameState.add_character("coralyn")
	GameState.save_now()
	var loaded := SaveService.load_save()
	_check("save contains 4 owned characters", loaded.get("roster", []).size() == 4, str(loaded.get("roster", []).size()))
	GameState._load_from_dict(loaded)
	_check("round trip keeps 4 owned characters", GameState.roster.size() == 4, str(GameState.roster.size()))
	_check("round trip keeps gerald/lilith/kael", GameState.owns_character("gerald") and GameState.owns_character("lilith") and GameState.owns_character("kael"))
	_check("round trip keeps party size", GameState.party.size() == 4, str(GameState.party.size()))


func _check_combat() -> void:
	GameState.new_game("Combat Verify")
	var units := CombatFactory.player_units()
	_check("combat builds 3 player units", units.size() == 3, str(units.size()))
	var names: Array = []
	for unit in units:
		names.append(unit.display_name)
	_check("combat units are Gerald, Lilith, Kael Ashford", names == ["Gerald", "Lilith", "Kael Ashford"], str(names))
