class_name CharacterStatusAnchor
extends Node2D
## Reusable anchor for status/condition visuals (buffs, debuffs, markers).
## Presentation-only hook; gameplay state remains in combat/progression systems.

signal status_slots_changed

@export var max_icons: int = 6
@export var icon_spacing: float = 14.0

var _slots: Array[Node2D] = []


func _ready() -> void:
	for child in get_children():
		if child is Node2D:
			_slots.append(child as Node2D)


func add_slot(slot: Node2D) -> void:
	if slot == null or _slots.has(slot):
		return
	if slot.get_parent() != self:
		add_child(slot)
	_slots.append(slot)
	_reflow()
	status_slots_changed.emit()


func clear_slots() -> void:
	for slot in _slots:
		if is_instance_valid(slot):
			slot.queue_free()
	_slots.clear()
	status_slots_changed.emit()


func get_slots() -> Array[Node2D]:
	return _slots.duplicate()


func _reflow() -> void:
	var x := 0.0
	for slot in _slots:
		if not is_instance_valid(slot):
			continue
		slot.position = Vector2(x, 0)
		x += icon_spacing
