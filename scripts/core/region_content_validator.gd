class_name RegionContentValidator
extends RefCounted
## Schema validation for region definitions and optional world extensions.
## Shared primitive checks remain centralized in ContentValidator.

static func validate_regions(data: Dictionary, context: Dictionary, prop_types: Array, weather_bias_states: Array, connection_kinds: Array) -> Array[String]:
	var errors: Array[String] = []
	var file := "regions.json"
	var root := "regions"
	var groups: Dictionary = context.get("enemy_groups.json", {})

	for raw_id in data.keys():
		var id := str(raw_id)
		var path := root + "." + id
		if not ContentValidator._valid_id(id):
			ContentValidator._err(errors, file, path, "ID must be lower_snake_case")
		var entry: Variant = data[raw_id]
		if typeof(entry) != TYPE_DICTIONARY:
			ContentValidator._err(errors, file, path, "expected an object")
			continue
		var region: Dictionary = entry

		ContentValidator._require_nonempty_string(region, "name", path, file, errors)
		ContentValidator._optional_string(region, "subtitle", path, file, errors)
		ContentValidator._require_int(region, "chunk_size", path, file, errors, 1)
		ContentValidator._require_int(region, "tile_width", path, file, errors, 1)
		ContentValidator._require_int(region, "tile_height", path, file, errors, 1)
		ContentValidator._require_int(region, "load_radius", path, file, errors, 0)
		ContentValidator._require_int(region, "noise_seed", path, file, errors, -2147483648, 2147483647)
		ContentValidator._require_number(region, "clearing_radius", path, file, errors, 0.0)

		var spawn_grid: Variant = region.get("spawn_grid", null)
		if spawn_grid == null:
			ContentValidator._err(errors, file, path + ".spawn_grid", "required field is missing")
		else:
			ContentValidator._validate_grid(spawn_grid, path + ".spawn_grid", file, errors)

		var biome = ContentValidator._require(region, "biome", "dictionary", path, file, errors)
		if typeof(biome) == TYPE_DICTIONARY:
			var biome_dict: Dictionary = biome
			ContentValidator._require_number(biome_dict, "water_level", path + ".biome", file, errors)
			ContentValidator._require_number(biome_dict, "deep_water_level", path + ".biome", file, errors)
			ContentValidator._validate_color_array(biome_dict, "grass_colors", path + ".biome", file, errors)
			for key in ["path_color", "water_shallow", "water_deep"]:
				var color := ContentValidator._require_nonempty_string(biome_dict, key, path + ".biome", file, errors)
				if not color.is_empty() and not ContentValidator._is_color(color):
					ContentValidator._err(errors, file, path + ".biome." + key, "expected a #rrggbb colour")

		var props = ContentValidator._require(region, "props", "array", path, file, errors)
		if typeof(props) == TYPE_ARRAY:
			var prop_list: Array = props
			if prop_list.is_empty():
				ContentValidator._err(errors, file, path + ".props", "must contain at least one prop")
			for index in prop_list.size():
				var prop: Variant = prop_list[index]
				var prop_path := "%s.props[%d]" % [path, index]
				if typeof(prop) != TYPE_DICTIONARY:
					ContentValidator._err(errors, file, prop_path, "expected an object")
					continue
				var prop_dict: Dictionary = prop
				ContentValidator._require_enum(prop_dict, "type", prop_types, prop_path, file, errors)
				ContentValidator._require_number(prop_dict, "weight", prop_path, file, errors, 0.0)
				ContentValidator._require_number(prop_dict, "min_elevation", prop_path, file, errors)

		var pois: Variant = region.get("pois", null)
		if pois != null:
			if typeof(pois) != TYPE_ARRAY:
				ContentValidator._err(errors, file, path + ".pois", "expected an array")
			else:
				var poi_ids: Dictionary = {}
				var poi_list: Array = pois
				for index in poi_list.size():
					var poi: Variant = poi_list[index]
					var poi_path := "%s.pois[%d]" % [path, index]
					if typeof(poi) != TYPE_DICTIONARY:
						ContentValidator._err(errors, file, poi_path, "expected an object")
						continue
					var poi_dict: Dictionary = poi
					var poi_id := ContentValidator._require_nonempty_string(poi_dict, "id", poi_path, file, errors)
					if not poi_id.is_empty():
						if poi_ids.has(poi_id):
							ContentValidator._err(errors, file, poi_path + ".id", "duplicate POI id '%s'" % poi_id)
						poi_ids[poi_id] = true
					ContentValidator._require_nonempty_string(poi_dict, "name", poi_path, file, errors)
					var grid: Variant = poi_dict.get("grid", null)
					if grid == null:
						ContentValidator._err(errors, file, poi_path + ".grid", "required field is missing")
					else:
						ContentValidator._validate_grid(grid, poi_path + ".grid", file, errors)
					ContentValidator._require_nonempty_string(poi_dict, "type", poi_path, file, errors)

		var spawns: Variant = region.get("spawns", null)
		if spawns != null:
			if typeof(spawns) != TYPE_ARRAY:
				ContentValidator._err(errors, file, path + ".spawns", "expected an array")
			else:
				var spawn_list: Array = spawns
				for index in spawn_list.size():
					var spawn: Variant = spawn_list[index]
					var spawn_path := "%s.spawns[%d]" % [path, index]
					if typeof(spawn) != TYPE_DICTIONARY:
						ContentValidator._err(errors, file, spawn_path, "expected an object")
						continue
					var spawn_dict: Dictionary = spawn
					var group_id := ContentValidator._require_nonempty_string(spawn_dict, "group", spawn_path, file, errors)
					if not group_id.is_empty() and not groups.has(group_id):
						ContentValidator._err(errors, file, spawn_path + ".group", "references missing enemy group '%s'" % group_id)
					var grid: Variant = spawn_dict.get("grid", null)
					if grid == null:
						ContentValidator._err(errors, file, spawn_path + ".grid", "required field is missing")
					else:
						ContentValidator._validate_grid(grid, spawn_path + ".grid", file, errors)
					ContentValidator._require_number(spawn_dict, "radius", spawn_path, file, errors, 0.0)
					ContentValidator._require_int(spawn_dict, "count", spawn_path, file, errors, 1)

		# Strict validation for the OPTIONAL multi-region / world-coordinate
		# fields. Missing fields produce NO error (backwards compatible); when a
		# field is present its structure and cross-references are checked.
		_validate_region_extensions(region, id, path, file, errors, data, weather_bias_states, connection_kinds)

	return errors


# ------------------------------------------------------- optional region links

static func _validate_region_extensions(
	region: Dictionary,
	id: String,
	path: String,
	file: String,
	errors: Array[String],
	data: Dictionary,
	weather_bias_states: Array,
	connection_kinds: Array
) -> void:
	# world_origin: array of exactly two numbers (a LOGICAL global/world offset).
	if region.has("world_origin"):
		ContentValidator._validate_grid(region["world_origin"], path + ".world_origin", file, errors)

	# environment: dictionary describing the region's ambient character.
	if region.has("environment"):
		var env: Variant = region["environment"]
		var env_path := path + ".environment"
		if typeof(env) != TYPE_DICTIONARY:
			ContentValidator._err(errors, file, env_path, "expected an object")
		else:
			var env_dict: Dictionary = env
			ContentValidator._require_nonempty_string(env_dict, "zone", env_path, file, errors)
			if env_dict.has("weather_bias"):
				var bias: Variant = env_dict["weather_bias"]
				var bias_path := env_path + ".weather_bias"
				if typeof(bias) != TYPE_ARRAY:
					ContentValidator._err(errors, file, bias_path, "expected an array")
				else:
					var bias_list: Array = bias
					for index in bias_list.size():
						var state: Variant = bias_list[index]
						var state_path := "%s[%d]" % [bias_path, index]
						if typeof(state) != TYPE_STRING:
							ContentValidator._err(errors, file, state_path, "expected a weather state string")
						elif not weather_bias_states.has(str(state)):
							ContentValidator._err(errors, file, state_path, "must be one of: %s" % ", ".join(weather_bias_states))
			if env_dict.has("fog_density"):
				ContentValidator._require_number(env_dict, "fog_density", env_path, file, errors, 0.0, 1.0)
			if env_dict.has("ambient_tint"):
				var tint := ContentValidator._require_nonempty_string(env_dict, "ambient_tint", env_path, file, errors)
				if not tint.is_empty() and not ContentValidator._is_color(tint):
					ContentValidator._err(errors, file, env_path + ".ambient_tint", "expected a #rrggbb colour")
			if env_dict.has("ambient_music"):
				ContentValidator._optional_string(env_dict, "ambient_music", env_path, file, errors)

	# entry_points: dictionary of lower_snake_case id -> 2-number grid.
	var entry_ids: Dictionary = {}
	if region.has("entry_points"):
		var eps: Variant = region["entry_points"]
		var eps_path := path + ".entry_points"
		if typeof(eps) != TYPE_DICTIONARY:
			ContentValidator._err(errors, file, eps_path, "expected an object")
		else:
			var eps_dict: Dictionary = eps
			for raw_key in eps_dict.keys():
				var key := str(raw_key)
				var key_path := eps_path + "." + key
				if not ContentValidator._valid_id(key):
					ContentValidator._err(errors, file, key_path, "entry point id must be lower_snake_case")
				entry_ids[key] = true
				ContentValidator._validate_grid(eps_dict[raw_key], key_path, file, errors)

	# connections: cross-region travel edges. `data` holds ALL region definitions,
	# so destination entry points can be resolved here without any I/O.
	if region.has("connections"):
		var conns: Variant = region["connections"]
		var conns_path := path + ".connections"
		if typeof(conns) != TYPE_ARRAY:
			ContentValidator._err(errors, file, conns_path, "expected an array")
		else:
			var conn_list: Array = conns
			var seen_ids: Dictionary = {}
			for index in conn_list.size():
				var conn: Variant = conn_list[index]
				var conn_path := "%s[%d]" % [conns_path, index]
				if typeof(conn) != TYPE_DICTIONARY:
					ContentValidator._err(errors, file, conn_path, "expected an object")
					continue
				var c: Dictionary = conn

				var cid := ContentValidator._require_nonempty_string(c, "id", conn_path, file, errors)
				if not cid.is_empty():
					if not ContentValidator._valid_id(cid):
						ContentValidator._err(errors, file, conn_path + ".id", "connection id must be lower_snake_case")
					if seen_ids.has(cid):
						ContentValidator._err(errors, file, conn_path + ".id", "duplicate connection id '%s'" % cid)
					seen_ids[cid] = true

				var to := ContentValidator._require_nonempty_string(c, "to", conn_path, file, errors)
				if not to.is_empty():
					if to == id:
						ContentValidator._err(errors, file, conn_path + ".to", "region connection cannot target itself")
					if not data.has(to):
						ContentValidator._err(errors, file, conn_path + ".to", "references missing region '%s'" % to)

				var via := ContentValidator._require_nonempty_string(c, "via", conn_path, file, errors)
				if not via.is_empty() and not entry_ids.has(via):
					ContentValidator._err(errors, file, conn_path + ".via", "references missing entry point '%s' in region '%s'" % [via, id])

				var entry := ContentValidator._require_nonempty_string(c, "entry", conn_path, file, errors)
				if not entry.is_empty() and data.has(to) and to != id:
					var dest_eps := RegionGraphValidator.entry_point_ids(data[to])
					if not dest_eps.has(entry):
						ContentValidator._err(errors, file, conn_path + ".entry", "references missing entry point '%s' in destination region '%s'" % [entry, to])

				ContentValidator._require_enum(c, "kind", connection_kinds, conn_path, file, errors)
				ContentValidator._require_nonempty_string(c, "label", conn_path, file, errors)


