extends Node2D
## Standalone visual testbed for modular forest composition and atmosphere.
## Keys 1/2/3 jump to day/dusk/night; the scene then slowly advances.

const ENVIRONMENT_SCENE: PackedScene = preload("res://scenes/environment/forest/forest_environment.tscn")

var environment: ModularForestEnvironment
var cycle_enabled: bool = true
var cycle_rate: float = 0.0018


func _ready() -> void:
	queue_redraw()
	var camera := Camera2D.new()
	camera.name = "PreviewCamera"
	camera.position = Vector2.ZERO
	camera.zoom = Vector2(0.88, 0.88)
	camera.enabled = true
	add_child(camera)
	var overlay := CanvasLayer.new()
	add_child(overlay)
	var controls := Label.new()
	controls.text = "FOREST SYSTEM PREVIEW   1 DAY   2 DUSK   3 NIGHT   SPACE PAUSE   UP/DOWN WIND"
	controls.position = Vector2(18, 16)
	controls.add_theme_color_override("font_color", Color(0.82, 0.94, 0.84))
	controls.add_theme_color_override("font_shadow_color", Color(0.02, 0.04, 0.03, 0.9))
	controls.add_theme_constant_override("shadow_offset_x", 1)
	controls.add_theme_constant_override("shadow_offset_y", 1)
	overlay.add_child(controls)
	environment = ENVIRONMENT_SCENE.instantiate() as ModularForestEnvironment
	add_child(environment)
	environment.time_of_day = 0.82
	_build_preview()
	environment.set_time_of_day(0.82)


func _process(delta: float) -> void:
	if cycle_enabled and environment != null:
		environment.set_time_of_day(environment.time_of_day + delta * cycle_rate)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1:
			environment.set_time_of_day(0.48)
		KEY_2:
			environment.set_time_of_day(0.80)
		KEY_3:
			environment.set_time_of_day(0.96)
		KEY_SPACE:
			cycle_enabled = not cycle_enabled
		KEY_UP:
			environment.set_wind_intensity(1.7)
		KEY_DOWN:
			environment.set_wind_intensity(0.35)


func _build_preview() -> void:
	var ground := Polygon2D.new()
	ground.name = "ForestFloor"
	ground.polygon = PackedVector2Array([
		Vector2(-620, -210), Vector2(-390, -430), Vector2(240, -470),
		Vector2(600, -240), Vector2(650, 180), Vector2(360, 430),
		Vector2(-320, 420), Vector2(-650, 150)
	])
	ground.color = Color(0.105, 0.19, 0.135, 1.0)
	environment.ground.add_child(ground)

	var moss_island := Polygon2D.new()
	moss_island.name = "MossIsland"
	moss_island.polygon = PackedVector2Array([
		Vector2(-470, -80), Vector2(-310, -250), Vector2(10, -300),
		Vector2(330, -190), Vector2(450, 40), Vector2(270, 260),
		Vector2(-90, 300), Vector2(-390, 180)
	])
	moss_island.color = Color(0.14, 0.25, 0.17, 0.72)
	environment.ground.add_child(moss_island)

	# Rear tree line first; shared Y-sort keeps all trunks/canopies depth-correct.
	environment.add_tree("pine_tree", Vector2(-430, -150), 1.05, 0)
	environment.add_tree("birch_tree", Vector2(-280, -240), 1.15, 1, true)
	environment.add_tree("willow_tree", Vector2(-90, -285), 1.25, 0)
	environment.add_tree("blossom_tree", Vector2(145, -255), 1.12, 2, true)
	environment.add_tree("dead_tree", Vector2(365, -155), 1.05, 1)
	environment.add_tree("pine_tree", Vector2(480, 20), 1.18, 2, true)
	environment.add_tree("willow_tree", Vector2(-500, 150), 1.05, 1)

	# Mid-ground understory: ordinary foliage and magical glow families.
	environment.add_prop("fern", Vector2(-360, 10), 1.15, 1)
	environment.add_prop("bush", Vector2(-220, 95), 1.0, 0)
	environment.add_prop("berry_bush", Vector2(-80, 120), 1.0, 2)
	environment.add_prop("flower_cluster", Vector2(80, 80), 1.15, 1)
	environment.add_prop("reeds", Vector2(250, 170), 1.0, 0)
	environment.add_prop("glow_mushroom", Vector2(-260, 245), 1.2, 1)
	environment.add_prop("spirit_bloom", Vector2(-35, 250), 1.35, 2)
	environment.add_prop("crystal_cluster", Vector2(190, 270), 1.05, 1, false, "landmark")
	environment.add_prop("rune_stone", Vector2(355, 240), 1.0, 0, false, "landmark")
	environment.add_fallen_log(Vector2(20, 350))
	environment.add_stump(Vector2(-410, 320))
	environment.add_root_cluster(Vector2(430, 330))

	for point in [
		Vector2(-310, -20), Vector2(-160, 190), Vector2(30, -60),
		Vector2(170, 20), Vector2(300, 110), Vector2(80, 330),
		Vector2(-80, 350), Vector2(390, -20)
	]:
		environment.add_firefly(point)


func _draw() -> void:
	# Quiet backdrop outside the playable forest-floor polygon.
	draw_rect(Rect2(Vector2(-1600, -1000), Vector2(3200, 2000)), Color(0.035, 0.055, 0.06), true)
