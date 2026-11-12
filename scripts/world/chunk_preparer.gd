class_name ChunkPreparer
extends RefCounted
## Bounded, main-thread, FRAME-SLICED chunk-preparation queue.
##
## This class is PURE and headless-testable: it creates NO nodes and touches NO
## SceneTree / RNG / file I/O. It only stores/retrieves OPAQUE chunk-data
## Dictionaries (the results of ChunkBuilder.build). The world OWNS those data's
## nodes and is responsible for freeing them on eviction / clear / teardown.
##
## WHY NO THREADS: MultiMesh / Image / ShaderMaterial creation and every
## scene-tree operation are NOT thread-safe in Godot 4. Chunk generation therefore
## stays on the MAIN THREAD and is FRAME-SLICED — the world builds at most ONE
## prepared chunk per frame during _process, keeping the frame budget bounded
## while never touching the SceneTree off-thread. This class is deliberately just
## the deterministic scheduling + bounded LRU cache for that work.

const DEFAULT_CAPACITY := 8
const MAX_PENDING := 32
const EMPTY_COORD := Vector2i(2147483647, 2147483647)

var _pending: Array = []          # Vector2i coords awaiting preparation
var _cache: Dictionary = {}       # Vector2i -> opaque chunk-data Dictionary
var _order: Array = []            # LRU order of Vector2i (front = oldest)
var _capacity: int = DEFAULT_CAPACITY


func _init(capacity: int = DEFAULT_CAPACITY) -> void:
	_capacity = maxi(1, capacity)


func request(coord: Vector2i) -> void:
	if _cache.has(coord) or _pending.has(coord):
		return
	if _pending.size() >= MAX_PENDING:
		return
	_pending.append(coord)


func request_many(coords: Array) -> void:
	for entry in coords:
		if entry is Vector2i:
			request(entry)


func pending_count() -> int:
	return _pending.size()


func next_pending() -> Vector2i:
	# Consumes (dequeues) the next coordinate so exactly one chunk is prepared
	# per frame. Returns EMPTY_COORD when nothing is queued.
	if _pending.is_empty():
		return EMPTY_COORD
	return _pending.pop_front()


func store(coord: Vector2i, data) -> void:
	if _cache.has(coord):
		_cache[coord] = data
		_touch(coord)
		return
	_cache[coord] = data
	_order.append(coord)
	# Bounded LRU: evict the oldest until within capacity. O(1)-ish; the world
	# frees the evicted data's nodes (this class never touches nodes).
	while _cache.size() > _capacity and not _order.is_empty():
		var oldest: Vector2i = _order.pop_front()
		if _cache.has(oldest):
			_cache.erase(oldest)


func has_prepared(coord: Vector2i) -> bool:
	return _cache.has(coord)


func take(coord: Vector2i) -> Variant:
	# Returns the data and removes it from the cache (the caller now owns the
	# nodes in the returned Dictionary).
	if not _cache.has(coord):
		return null
	var data: Variant = _cache[coord]
	_cache.erase(coord)
	var idx := _order.find(coord)
	if idx >= 0:
		_order.remove_at(idx)
	var pidx := _pending.find(coord)
	if pidx >= 0:
		_pending.remove_at(pidx)
	return data


func peek(coord: Vector2i) -> Variant:
	return _cache.get(coord, null)


func evict(coord: Vector2i) -> void:
	if _cache.has(coord):
		_cache.erase(coord)
	var idx := _order.find(coord)
	if idx >= 0:
		_order.remove_at(idx)


func clear() -> void:
	_pending.clear()
	_cache.clear()
	_order.clear()


func stats() -> Dictionary:
	return {
		"pending": _pending.size(),
		"cached": _cache.size(),
		"capacity": _capacity,
	}


func _touch(coord: Vector2i) -> void:
	var idx := _order.find(coord)
	if idx >= 0:
		_order.remove_at(idx)
	_order.append(coord)
