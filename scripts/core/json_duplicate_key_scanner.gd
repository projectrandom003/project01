class_name JsonDuplicateKeyScanner
extends RefCounted
## Pure JSON duplicate-object-key scanner. Kept separate from domain schema validation.

static func scan_duplicate_keys(file_name: String, text: String) -> Array[String]:
	var errors: Array[String] = []
	_scan_value(text, 0, file_name, "", errors)
	return errors


static func _scan_value(text: String, index: int, file_name: String, path: String, errors: Array[String]) -> int:
	index = _skip_ws(text, index)
	if index >= text.length():
		return index
	var character := text[index]
	match character:
		"{":
			return _scan_object(text, index, file_name, path, errors)
		"[":
			return _scan_array(text, index, file_name, path, errors)
		"\"":
			return _scan_string(text, index)
		_:
			while index < text.length() and not ",]} \t\r\n".contains(text[index]):
				index += 1
			return index


static func _scan_object(text: String, index: int, file_name: String, path: String, errors: Array[String]) -> int:
	index += 1
	var keys: Dictionary = {}
	index = _skip_ws(text, index)
	if index < text.length() and text[index] == "}":
		return index + 1
	while index < text.length():
		index = _skip_ws(text, index)
		if index >= text.length() or text[index] != "\"":
			return index
		var key_start := index
		index = _scan_string(text, index)
		var key := text.substr(key_start + 1, maxi(0, index - key_start - 2))
		if keys.has(key):
			var location := path if not path.is_empty() else "(root)"
			ContentValidator._err(errors, file_name, location, "duplicate key '%s'" % key)
		keys[key] = true
		index = _skip_ws(text, index)
		if index < text.length() and text[index] == ":":
			index += 1
		var child_path := key if path.is_empty() else path + "." + key
		index = _scan_value(text, index, file_name, child_path, errors)
		index = _skip_ws(text, index)
		if index < text.length() and text[index] == ",":
			index += 1
			continue
		if index < text.length() and text[index] == "}":
			return index + 1
		return index
	return index


static func _scan_array(text: String, index: int, file_name: String, path: String, errors: Array[String]) -> int:
	index += 1
	var item_index := 0
	index = _skip_ws(text, index)
	if index < text.length() and text[index] == "]":
		return index + 1
	while index < text.length():
		var child_path := "%s[%d]" % [path, item_index]
		index = _scan_value(text, index, file_name, child_path, errors)
		index = _skip_ws(text, index)
		if index < text.length() and text[index] == ",":
			item_index += 1
			index += 1
			continue
		if index < text.length() and text[index] == "]":
			return index + 1
		return index
	return index


static func _scan_string(text: String, index: int) -> int:
	index += 1
	while index < text.length():
		var character := text[index]
		if character == "\\":
			index += 2
		elif character == "\"":
			return index + 1
		else:
			index += 1
	return index


static func _skip_ws(text: String, index: int) -> int:
	while index < text.length() and " \t\r\n".contains(text[index]):
		index += 1
	return index
