class_name GroundChunk
extends Node2D
## Continuous chunk-sized ground surface prototype (render-only).
## Replaces per-tile diamond MultiMesh quads for a single representative chunk to
## remove the repeating diamond lattice while preserving grid/collision/navigation/
## streaming, and gameplay (all data-driven elsewhere).

@onready var terrain_surface: MeshInstance2D = $TerrainSurface

const TERRAIN_SHADER := preload("res://resources/shaders/terrain_continuous.gdshader")


func setup(coord: Vector2i, chunk_size: int, tile_colors: Array, origin_grid: Vector2) -> void:
	# tile_colors: row-major [oy * chunk_size + ox] = Color (land/water base for this chunk).
	var image := Image.create(chunk_size, chunk_size, false, Image.FORMAT_RGBA8)
	for oy in chunk_size:
		for ox in chunk_size:
			var idx: int = oy * chunk_size + ox
			var c: Color = tile_colors[idx] if idx < tile_colors.size() else Color(0, 0, 0, 0)
			image.set_pixel(ox, oy, c)
	var tex := ImageTexture.create_from_image(image)

	var mat := ShaderMaterial.new()
	mat.shader = TERRAIN_SHADER
	mat.set_shader_parameter("tile_colors", tex)
	mat.set_shader_parameter("chunk_origin_grid", origin_grid)
	mat.set_shader_parameter("chunk_size", Vector2(chunk_size, chunk_size))
	mat.set_shader_parameter("tile_w", IsoMath.TILE_W)
	mat.set_shader_parameter("tile_h", IsoMath.TILE_H)

	# Size quad to cover the full chunk diamond in world space.
	var minp := Vector2(INF, INF)
	var maxp := Vector2(-INF, -INF)
	for oy in chunk_size:
		for ox in chunk_size:
			var wp := IsoMath.grid_to_world(origin_grid.x + ox, origin_grid.y + oy)
			minp.x = minf(minp.x, wp.x - IsoMath.TILE_W)
			minp.y = minf(minp.y, wp.y - IsoMath.TILE_H)
			maxp.x = maxf(maxp.x, wp.x + IsoMath.TILE_W)
			maxp.y = maxf(maxp.y, wp.y + IsoMath.TILE_H)
	var margin := 8.0
	minp -= Vector2(margin, margin)
	maxp += Vector2(margin, margin)
	var size := maxp - minp
	var center := (minp + maxp) * 0.5

	var mesh := QuadMesh.new()
	mesh.size = size
	terrain_surface.mesh = mesh
	terrain_surface.material = mat
	terrain_surface.position = center
	terrain_surface.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
