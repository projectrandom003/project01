class_name CastleExpansionComponent
extends Node2D
## Scene composition root for the Royal Gardens expansion.
## Child components independently own approach dressing, cache placement and portal linking.

func _ready() -> void:
	for component_name in ["ApproachBuilder", "CacheSpawner", "PortalConnector"]:
		if get_node_or_null(component_name) == null:
			push_error("Castle expansion is missing component: %s" % component_name)
