class_name LoadingScreen
extends Control
## Composition root for the untouched loading artwork and its independent loader node.

signal scene_loaded(scene: PackedScene)
signal load_failed

var target_scene_path := "res://scenes/game.tscn"
@onready var resource_component: LoadingResourceComponent = $ResourceLoader

func _ready() -> void:
	UIFactory.set_full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var artwork := get_node_or_null("ReverieLoadingArtwork") as TextureRect
	if artwork != null and artwork.texture == null:
		artwork.visible = false
		var fallback := LaunchForestBackdrop.new()
		UIFactory.set_full_rect(fallback)
		add_child(fallback)
	var party_layer := get_node_or_null("PartyLayer") as Node2D
	if party_layer != null:
		party_layer.visible = false
	resource_component.scene_loaded.connect(scene_loaded.emit)
	resource_component.load_failed.connect(load_failed.emit)
	resource_component.begin(target_scene_path)
