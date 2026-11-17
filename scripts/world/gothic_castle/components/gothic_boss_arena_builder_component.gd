class_name GothicBossArenaBuilderComponent
extends Node
## Authored Gothic Castle environment responsibility node.

var environment: GothicCastleEnvironmentComponent

func configure(owner: GothicCastleEnvironmentComponent) -> void:
	environment = owner

func _build_arena() -> void:
	var a := ReverieRouteData.ARENA_CENTER
	environment._place("Boss_Arena", "Flooring", "arena_floor_sigil_2x2", a, environment.arena_layer, -18)
	# Boundary ring, open only toward the road (grid x < arena.x).
	for x in range(a.x - ReverieRouteData.ARENA_RADIUS, a.x + ReverieRouteData.ARENA_RADIUS + 1):
		if x == a.x:
			continue
		environment._place("Boss_Arena", "Architecture", "arena_wall_x_2x1", Vector2i(x, a.y - 8), environment.arena_layer)
		environment._place("Boss_Arena", "Architecture", "arena_wall_x_2x1", Vector2i(x, a.y + 8), environment.arena_layer)
	for y in range(a.y - 7, a.y + 8):
		if absi(y - a.y) <= 1:
			continue
		environment._place("Boss_Arena", "Architecture", "arena_wall_y_1x2", Vector2i(a.x + 8, y), environment.arena_layer)
	for anchor in [Vector2i(a.x - 8, a.y - 8), Vector2i(a.x + 7, a.y - 8),
					Vector2i(a.x - 8, a.y + 6), Vector2i(a.x + 7, a.y + 6)]:
		environment._place("Boss_Arena", "Architecture", "arena_tower_2x2", anchor, environment.arena_layer)
		environment._place("Gothic_Castle", "Towers", "tower_roof_corrupt_1x1", anchor, environment.arena_layer)
	for anchor in [Vector2i(a.x - 5, a.y - 4), Vector2i(a.x + 4, a.y - 4),
					Vector2i(a.x - 5, a.y + 3), Vector2i(a.x + 4, a.y + 3)]:
		environment._place("Boss_Arena", "Architecture", "arena_pillar_tall", anchor, environment.arena_layer)
	for anchor in [Vector2i(a.x - 3, a.y - 6), Vector2i(a.x + 2, a.y + 5)]:
		environment._place("Boss_Arena", "Architecture", "arena_pillar_broken", anchor, environment.arena_layer)
	environment._place("Boss_Arena", "Architecture", "arena_throne_dais_2x2",
			Vector2i(a.x + 1, a.y - 1), environment.arena_layer)
	environment._place("Boss_Arena", "Architecture", "arena_gate_3x1", Vector2i(a.x - 9, a.y), environment.arena_layer)
	environment._place("Boss_Arena", "Architecture", "arena_arch_large_3x1", Vector2i(a.x, a.y - 7), environment.arena_layer)
	for anchor in [Vector2i(a.x - 6, a.y - 3), Vector2i(a.x + 5, a.y + 2)]:
		environment._place("Boss_Arena", "Decorations", "brazier_boss_large", anchor, environment.arena_layer)
	for anchor in [Vector2i(a.x - 7, a.y + 4), Vector2i(a.x + 6, a.y - 5)]:
		environment._place("Boss_Arena", "Decorations", "banner_boss_a", anchor, environment.arena_layer)
		environment._place("Boss_Arena", "Decorations", "altar_skull_01", Vector2i(anchor.x + 1, anchor.y + 1), environment.arena_layer)
	environment._place("Boss_Arena", "Decorations", "statue_baltoria_guardian", Vector2i(a.x - 2, a.y - 5), environment.arena_layer)
	environment._place("Boss_Arena", "Decorations", "statue_baltoria_winged", Vector2i(a.x + 2, a.y + 5), environment.arena_layer)
	environment._place("Boss_Arena", "Decorations", "dark_crystal_02", Vector2i(a.x + 6, a.y + 4), environment.arena_layer)
	environment._place("Corrupted_Environment", "Effects", "purple_glow_soft", a, environment.effects_layer, 1)
	environment._place("Corrupted_Environment", "Effects", "light_shaft_purple", Vector2i(a.x, a.y - 2), environment.effects_layer, 1)
