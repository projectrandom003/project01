class_name WorldWeatherComponent
extends Node
## Owns the deterministic weather director lifecycle for a world region.
## Rendering remains with GreenwardWorld; this component only owns weather state.

var director: WeatherDirector


func configure(region: Dictionary, presentation_bias: Array = []) -> WeatherDirector:
	var seed_value := int(region.get("noise_seed", 1337)) + 505
	director = WeatherDirector.new(seed_value)
	var environment: Variant = region.get("environment", {})
	var bias: Array = presentation_bias
	if bias.is_empty() and typeof(environment) == TYPE_DICTIONARY:
		var region_bias: Variant = environment.get("weather_bias", [])
		if typeof(region_bias) == TYPE_ARRAY:
			bias = region_bias
	if not bias.is_empty():
		director.set_state(_state_from_name(str(bias[0])))
	return director


func tick(delta: float) -> bool:
	return director.tick(delta) if director != null else false


func params() -> Dictionary:
	return director.params() if director != null else {}


func _state_from_name(state_name: String) -> int:
	match state_name:
		"mist": return WeatherDirector.MIST
		"rain": return WeatherDirector.RAIN
		"pollen_bloom": return WeatherDirector.POLLEN_BLOOM
		_: return WeatherDirector.CLEAR
