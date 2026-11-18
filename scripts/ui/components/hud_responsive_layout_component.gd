class_name HUDResponsiveLayoutComponent
extends Node
## Owns viewport-driven HUD layout adaptations for compact portrait and landscape.

var hud: HUD


func bind(owner_hud: HUD) -> void:
	hud = owner_hud


func apply(viewport_size: Vector2 = Vector2.ZERO) -> void:
	if hud == null or not hud.is_inside_tree():
		return
	if viewport_size == Vector2.ZERO:
		viewport_size = hud.get_viewport_rect().size
	var compact_portrait := viewport_size.x < 540.0 and viewport_size.y > viewport_size.x

	var party_panel := hud.get_node_or_null("PartyPanel") as Control
	if party_panel != null:
		party_panel.visible = not compact_portrait

	if hud._hint_label != null:
		hud._hint_label.visible = not compact_portrait

	if hud._minimap != null:
		if compact_portrait:
			hud._minimap.offset_left = -188.0
			hud._minimap.offset_top = 90.0
			hud._minimap.offset_right = -18.0
			hud._minimap.offset_bottom = 260.0
		else:
			hud._minimap.offset_left = -244.0
			hud._minimap.offset_top = 90.0
			hud._minimap.offset_right = -20.0
			hud._minimap.offset_bottom = 314.0

	var prompt_center := hud.get_node_or_null("PromptCenter") as Control
	if prompt_center != null:
		if compact_portrait:
			prompt_center.offset_top = -viewport_size.y * 0.62
			prompt_center.offset_bottom = -viewport_size.y * 0.54
		else:
			prompt_center.offset_top = -104.0
			prompt_center.offset_bottom = -34.0
