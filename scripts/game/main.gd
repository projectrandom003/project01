extends Control
## Composition root for the game startup and gameplay flow nodes.
@onready var startup_flow: MainStartupFlowComponent = $StartupFlow
@onready var gameplay_flow: MainGameplayFlowComponent = $GameplayFlow

func _ready() -> void:
	UIFactory.set_full_rect(self)
	theme = UITheme.build()
	startup_flow.bind(self)
	gameplay_flow.bind(self, startup_flow)
	startup_flow.quit_requested.connect(_quit)
	gameplay_flow.quit_requested.connect(_quit)
	startup_flow.begin()

func _quit() -> void:
	GameState.save_now()
	get_tree().quit()
