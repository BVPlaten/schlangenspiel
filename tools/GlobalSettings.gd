extends Node

var music_volume: int = 10
var sfx_volume: int = 10

const SETTINGS_FILE: String = "user://settings.json"

func _ready() -> void:
	setup_audio_buses()
	load_settings()
	apply_music_volume()
	apply_sfx_volume()

func setup_audio_buses() -> void:
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, "Music")
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, "SFX")

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_FILE):
		return # No settings file to load

	var file: FileAccess = FileAccess.open(SETTINGS_FILE, FileAccess.READ)
	if not file:
		push_error("Failed to open settings file for reading: %s" % FileAccess.get_open_error())
		return

	var json_text: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var error: Error = json.parse(json_text)
	if error != OK:
		push_error("Failed to parse settings JSON: %s" % json.get_error_message())
		return

	var data: Variant = json.get_data()
	if typeof(data) == TYPE_DICTIONARY:
		music_volume = data.get("music_volume", 10)
		sfx_volume = data.get("sfx_volume", 10)

func save_settings() -> void:
	var data: Dictionary = {
		"music_volume": music_volume,
		"sfx_volume": sfx_volume
	}
	
	var json_text: String = JSON.stringify(data, "\t")
	var file: FileAccess = FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if not file:
		push_error("Failed to open settings file for writing: %s" % FileAccess.get_open_error())
		return
		
	file.store_string(json_text)
	file.close()

func set_music_volume(volume: int) -> void:
	music_volume = clamp(volume, 0, 10)
	apply_music_volume()
	save_settings()

func set_sfx_volume(volume: int) -> void:
	sfx_volume = clamp(volume, 0, 10)
	apply_sfx_volume()
	save_settings()

func apply_music_volume() -> void:
	var bus_idx: int = AudioServer.get_bus_index("Music")
	if bus_idx != -1:
		var db_value: float = linear_to_db(music_volume / 10.0)
		AudioServer.set_bus_volume_db(bus_idx, db_value)
		AudioServer.set_bus_mute(bus_idx, music_volume == 0)

func apply_sfx_volume() -> void:
	var bus_idx: int = AudioServer.get_bus_index("SFX")
	if bus_idx != -1:
		var db_value: float = linear_to_db(sfx_volume / 10.0)
		AudioServer.set_bus_volume_db(bus_idx, db_value)
		AudioServer.set_bus_mute(bus_idx, sfx_volume == 0)

func linear_to_db(linear_volume: float) -> float:
	if linear_volume <= 0.0:
		return -80.0 # Effectively muted
	return 20.0 * log(linear_volume) / log(10.0)
