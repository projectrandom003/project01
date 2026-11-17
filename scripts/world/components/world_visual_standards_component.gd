class_name WorldVisualStandardsComponent
extends Node
## Validates and applies the region's visual contract, and exposes its report.

var world: GreenwardWorld


func configure(owner: GreenwardWorld) -> void:
	world = owner


func apply() -> void:
	if world == null:
		return
	world._visual_standards_valid = WorldVisualStandards.validate().is_empty()
	world._visual_standards_applied = true
	world._visual_standards_tint = WorldVisualStandards.region_tint(world.region_id)
	world._visual_standards_summary = WorldVisualStandards.summary()
	if world.fog_component != null:
		var seeded: Color = Color(0.8, 0.88, 0.95, 1.0).lerp(world._visual_standards_tint, 0.10)
		world.fog_component.apply_appearance(seeded, float(world.fog_material.get_shader_parameter("density")))
	elif world.fog_material != null:
		var seeded: Color = Color(0.8, 0.88, 0.95, 1.0).lerp(world._visual_standards_tint, 0.10)
		world.fog_material.set_shader_parameter("fog_color", seeded)


func report() -> Dictionary:
	if world == null:
		return {}
	var categories: Array[String] = WorldVisualStandards.categories()
	var applied: Array = []
	for category in categories:
		var standard: Dictionary = WorldVisualStandards.standard(category)
		applied.append({
			"category": category,
			"canvas": [int(standard.get("canvas_width", 0)), int(standard.get("canvas_height", 0))],
			"anchor": standard.get("anchor_vector", Vector2(0.5, 1.0)),
			"outline_px": int(standard.get("outline_px", 0)),
			"palette_group": str(standard.get("palette_group", "")),
		})
	return {
		"region_id": world.region_id,
		"standards_valid": WorldVisualStandards.validate().is_empty(),
		"applied_categories": applied,
		"region_tint": WorldVisualStandards.region_tint(world.region_id),
		"categories": categories,
		"summary": WorldVisualStandards.summary(),
		"applied": world._visual_standards_applied,
		"cached_valid": world._visual_standards_valid,
		"cached_summary": not world._visual_standards_summary.is_empty(),
		"final_assets": 0,
		"note": "Compositional/standards improvements only — ZERO final assets; all art is procedural placeholder.",
	}
