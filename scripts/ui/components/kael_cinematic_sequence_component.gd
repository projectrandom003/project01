class_name KaelCinematicSequenceComponent
extends Node
## Owns the authored prologue sequence data. No presentation or input logic lives here.

const SEQUENCE_PATH := "res://assets/cinematics/kael_prologue/kael_prologue_sequence.json"

var shots: Array[Dictionary] = []

func load_sequence() -> bool:
	shots.clear()
	if not FileAccess.file_exists(SEQUENCE_PATH):
		push_error("[KaelSequence] Missing sequence data: " + SEQUENCE_PATH)
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SEQUENCE_PATH))
	if not parsed is Dictionary:
		push_error("[KaelSequence] Sequence JSON must contain an object.")
		return false
	for item in parsed.get("shots", []):
		if item is Dictionary:
			shots.append(item)
	if shots.is_empty():
		push_error("[KaelSequence] No authored shots were found.")
		return false
	return true
