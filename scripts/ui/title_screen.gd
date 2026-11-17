class_name TitleScreen
extends Control
## Composition root: wires independently authored title-screen components.

signal menu_requested(action: String)
signal quit_requested

@onready var layout_component: TitleScreenLayoutComponent = $Layout
@onready var actions_component: TitleScreenActionsComponent = $Actions

func _ready() -> void:
	UIFactory.set_full_rect(self)
	layout_component.bind(self)
	actions_component.bind(self)
	actions_component.menu_requested.connect(menu_requested.emit)
	actions_component.quit_requested.connect(quit_requested.emit)
