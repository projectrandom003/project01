extends SceneTree
func _init() -> void:
	print("STRETCH_MODE=" + str(ClassDB.class_get_enum_constants("TextureRect", "StretchMode")))
	print("EXPAND_MODE=" + str(ClassDB.class_get_enum_constants("TextureRect", "ExpandMode")))
	quit()
