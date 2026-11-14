extends VBoxContainer

var _portrait: PortraitView
var _name_label: Label
var _level_label: Label


func setup(definition: CharacterDef, level: int) -> void:
	_portrait = get_node("Portrait") as PortraitView
	_name_label = get_node("Name") as Label
	_level_label = get_node("Level") as Label
	if definition != null:
		_portrait.setup_character(definition)
		_name_label.text = definition.display_name
	else:
		_name_label.text = "Unknown"
	_level_label.text = "Lv. %d" % level
