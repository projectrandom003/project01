extends Node
## Focused structural and data checks for Edgar's dedicated NPC scene.

var failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		printerr("FAIL: " + label)


func _run() -> void:
	var packed := load("res://scenes/world/npcs/edgar.tscn") as PackedScene
	_check(packed != null, "Edgar NPC scene loads")
	if packed == null:
		_finish()
		return
	var edgar := packed.instantiate() as WorldNPC
	get_tree().root.add_child(edgar)
	await get_tree().process_frame
	_check(edgar.npc_id == "edgar_market_keeper", "Edgar has stable NPC identity")
	_check(edgar.display_name == "Edgar", "Edgar display name is configured")
	_check(edgar.dialogue_id == "edgar_market_keeper", "Edgar dialogue identity is configured")
	_check(edgar.role == "Market Keeper", "Edgar market role is configured")
	_check(edgar.get_node_or_null("ActorVisual") != null, "Dedicated scene retains ActorVisual compatibility node")
	_check(edgar.get_node_or_null("EdgarArtwork") is Sprite2D, "Dedicated Edgar artwork sprite exists")
	_check(not (edgar.get_node("ActorVisual") as Node2D).visible, "Generic procedural placeholder is hidden")
	_check(edgar.get_node_or_null("MarketKeeperDetails/AccessoryMounts/GlassesMount") is Marker2D, "Glasses attachment marker exists")
	_check(edgar.get_node_or_null("MarketKeeperDetails/AccessoryMounts/CoatChainMount") is Marker2D, "Coat-chain attachment marker exists")
	_check(edgar.is_in_group("interactables"), "Edgar registers with existing interaction group")
	_check(edgar.interaction_radius == 92.0, "Edgar retains standard NPC interaction radius")
	var content_db: Node = get_tree().root.get_node_or_null("ContentDB")
	var dialogue: Dictionary = content_db.call("get_dialogue", "edgar_market_keeper") if content_db != null else {}
	_check(not dialogue.is_empty(), "Edgar dialogue data loads")
	_check(dialogue.get("start", "") == "greet", "Edgar dialogue has a valid start node")
	var nodes: Dictionary = dialogue.get("nodes", {})
	_check(nodes.has("greet") and nodes.has("market") and nodes.has("about"), "Edgar has authored introduction and market branches")
	var portrait_path := str(nodes.get("greet", {}).get("portrait_asset", ""))
	_check(portrait_path == "res://assets/characters/edgar/edgar_portrait.jpg", "Edgar dialogue references dedicated portrait path")
	edgar.queue_free()
	await get_tree().process_frame
	_finish()


func _finish() -> void:
	if failures.is_empty():
		print("verify_edgar_npc: OK")
		get_tree().quit(0)
	else:
		printerr("verify_edgar_npc: FAILED (%d)" % failures.size())
		get_tree().quit(1)
