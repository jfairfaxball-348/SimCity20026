extends RefCounted
const City = preload("res://scripts/sim/city_state.gd")
const Codec = preload("res://scripts/persistence/save_codec.gd")
const FileOps = preload("res://scripts/persistence/file_ops.gd")
var files: FileOps

func _init(storage: FileOps = null) -> void:
	files = storage if storage != null else FileOps.new()

func load_city(path: String) -> Dictionary:
	var read: Dictionary = files.read_text(path)
	if not read.ok:
		return read
	return Codec.decode(String(read.text))

func save_city(city: City, path: String) -> Dictionary:
	var text: String = JSON.stringify(city.snapshot(), "", true)
	var validated: Dictionary = Codec.decode(text)
	if not validated.ok:
		return Codec.fail("Current city could not be validated. Nothing was written.")
	var pending: String = path + ".tmp"
	var backup: String = path + ".bak"
	var err: Error = files.write_text(pending, text)
	if err != OK:
		return Codec.fail("Could not write temporary save (%s). Previous save retained." % error_string(err))
	var readback: Dictionary = load_city(pending)
	if not readback.ok or readback.city.canonical() != city.canonical():
		return Codec.fail("Temporary save verification failed. Previous save retained.")
	# Never rotate a corrupt primary over a good backup.
	if files.exists(path) and load_city(path).ok:
		err = files.copy_file(path, backup + ".tmp")
		if err != OK or not load_city(backup + ".tmp").ok:
			return Codec.fail("Could not prepare a verified backup. Previous save retained.")
		err = files.replace_file(backup + ".tmp", backup)
		if err != OK:
			return Codec.fail("Could not replace backup. Previous save retained.")
	err = files.replace_file(pending, path)
	if err != OK:
		return Codec.fail("Could not replace save (%s). Previous save or backup retained." % error_string(err))
	return {"ok": true, "message": "Saved locally. The previous valid save is kept as a backup."}
