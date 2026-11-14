class_name VillagePathVisualSegment
extends Node2D
## Authored village footpath segment. Geometry is rendered by child Line2D nodes.

@export var path_points: PackedVector2Array = PackedVector2Array()
@export_range(8.0, 96.0, 1.0) var path_width: float = 34.0
@export var edge_color: Color = Color("#88765d")
@export var surface_color: Color = Color("#b5a184")
@export var highlight_color: Color = Color("#c8b69a")

@onready var edge: Line2D = $Edge
@onready var surface: Line2D = $Surface
@onready var highlight: Line2D = $Highlight

func _ready() -> void:
	_apply_geometry()

func configure(points: PackedVector2Array, width: float = 34.0) -> void:
	path_points = points
	path_width = clampf(width, 8.0, 96.0)
	if is_node_ready():
		_apply_geometry()

func _apply_geometry() -> void:
	if path_points.size() < 2:
		return
	edge.points = path_points
	edge.width = path_width + 8.0
	edge.default_color = edge_color
	surface.points = path_points
	surface.width = path_width
	surface.default_color = surface_color
	highlight.points = path_points
	highlight.width = maxf(2.0, path_width * 0.12)
	highlight.default_color = highlight_color
	highlight.position = Vector2(0.0, -path_width * 0.16)
