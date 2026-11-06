extends RefCounted
## D39: remembered presentation settings in their own small, versioned file. Never part
## of a town save and never read by the model. Any invalid file gives all defaults.
const FileOps = preload("res://scripts/persistence/file_ops.gd")
const VERSION: int = 1
const MAX_BYTES: int = 4096
const DEFAULT_PATH: String = "user://settings.json"
const WINDOW_SIZES: Array[Vector2i] = [Vector2i(1280,720), Vector2i(1366,768), Vector2i(1920,1080), Vector2i(1280,800)]
const TEXT_SIZES: Array[int] = [16, 18, 20]
const ARTS: Array[String] = ["original", "tiny_city", "modern_city"]
const FLAGS: Array[String] = ["grid", "road_marks", "power_marks", "land_value", "services", "guide_hidden"]
## Tests point this at an isolated file before the main scene starts.
static var override_path: String = ""
var files: FileOps

func _init(storage: FileOps = null) -> void:
	files = storage if storage != null else FileOps.new()

static func path() -> String:
	return override_path if not override_path.is_empty() else DEFAULT_PATH

static func defaults() -> Dictionary:
	return {"settings_version": VERSION, "window": [], "text_size": 16, "art": "modern_city",
		"grid": true, "road_marks": true, "power_marks": true, "land_value": false, "services": false, "guide_hidden": false}

## Returns {"settings": Dictionary, "ok": bool, "message": String}; ok is false when the
## defaults replaced a missing or invalid file.
func load_settings() -> Dictionary:
	var file_path: String = path()
	if not files.exists(file_path): return {"settings": defaults(), "ok": false, "message": "No settings file; defaults used."}
	var read: Dictionary = files.read_text(file_path)
	if not read.ok or String(read.text).to_utf8_buffer().size() > MAX_BYTES:
		return {"settings": defaults(), "ok": false, "message": "Settings unreadable; defaults used."}
	var parser := JSON.new()
	if parser.parse(String(read.text)) != OK or not valid(parser.data):
		return {"settings": defaults(), "ok": false, "message": "Settings invalid; defaults used."}
	var data: Dictionary = parser.data
	var out: Dictionary = defaults()
	var window: Array = []
	for value in data.window: window.append(int(value))
	out.window = window
	out.text_size = int(data.text_size)
	out.art = String(data.art)
	for flag in FLAGS: out[flag] = bool(data[flag])
	return {"settings": out, "ok": true, "message": "Settings restored."}

static func whole(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and floor(float(value)) == float(value)

## Exactly the version-1 keys with allowed values.
static func valid(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or data.size() != defaults().size(): return false
	for key in defaults():
		if not data.has(key): return false
	if not whole(data.settings_version) or int(data.settings_version) != VERSION: return false
	if typeof(data.window) != TYPE_ARRAY: return false
	if not data.window.is_empty():
		if data.window.size() != 2 or not whole(data.window[0]) or not whole(data.window[1]): return false
		if not Vector2i(int(data.window[0]), int(data.window[1])) in WINDOW_SIZES: return false
	if not whole(data.text_size) or not int(data.text_size) in TEXT_SIZES: return false
	if typeof(data.art) != TYPE_STRING or not String(data.art) in ARTS: return false
	for flag in FLAGS:
		if typeof(data[flag]) != TYPE_BOOL: return false
	return true

## Validated temporary write, read back, then replace.
func save_settings(values: Dictionary) -> Dictionary:
	var data: Dictionary = defaults()
	for key in data:
		if values.has(key): data[key] = values[key]
	if not valid(data): return {"ok": false, "message": "Settings not saved: invalid values."}
	var text: String = JSON.stringify(data, "", true)
	var file_path: String = path()
	var pending: String = file_path + ".tmp"
	var err: Error = files.write_text(pending, text)
	if err != OK: return {"ok": false, "message": "Settings not saved (%s)." % error_string(err)}
	var back: Dictionary = files.read_text(pending)
	if not back.ok or String(back.text) != text: return {"ok": false, "message": "Settings not saved: verification failed."}
	err = files.replace_file(pending, file_path)
	if err != OK: return {"ok": false, "message": "Settings not saved (%s)." % error_string(err)}
	return {"ok": true, "message": "Settings saved."}
