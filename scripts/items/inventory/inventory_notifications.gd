class_name InventoryNotifications
extends RefCounted

signal notified(message: String, kind: String)

func notify(message: String, kind: String = "info") -> void:
	notified.emit(message, kind)
	EventBus.toast_requested.emit(message)
