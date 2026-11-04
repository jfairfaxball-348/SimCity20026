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
	var current: Dictionary = load_city(path) if files.exists(path) else {"ok": false}
	if current.ok:
		# An earlier-format primary or backup is copied before its first replacement
		# unless a preserved copy already exists (D20): rotation replaces both.
		var previous: Dictionary = load_city(backup) if files.exists(backup) else {"ok": false}
		for entry in [[path, current], [backup, previous]]:
			var old_schema: int = int(entry[1].get("schema", City.SCHEMA)) if entry[1].ok else City.SCHEMA
			if old_schema < City.SCHEMA:
				err = preserve_original(entry[0], path, old_schema)
				if err != OK:
					return Codec.fail("Could not keep a copy of the earlier-format save (%s). Previous save retained." % error_string(err))
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

## Earlier-format saves are copied byte-for-byte once, beside the primary, before
## their first replacement (D20). An existing preserved copy is never overwritten.
static func preserved_path(path: String, schema: int) -> String:
	return path.get_basename() + ".schema%d.json" % schema

func preserve_original(source: String, path: String, schema: int) -> Error:
	var preserved: String = preserved_path(path, schema)
	if files.exists(preserved):
		return OK
	var err: Error = files.copy_file(source, preserved + ".tmp")
	if err != OK:
		return err
	var original: Dictionary = files.read_text(source)
	var copy: Dictionary = files.read_text(preserved + ".tmp")
	if not original.ok or not copy.ok or String(copy.text) != String(original.text):
		return ERR_FILE_CORRUPT
	return files.replace_file(preserved + ".tmp", preserved)
