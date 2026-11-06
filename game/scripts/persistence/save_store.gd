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

## D39 autosaves: three rotating slots beside the manual save, written with the same
## validated temporary write but never touching the manual file, its backup or the
## preserved earlier-format copies.
const AUTOSAVE_SLOTS: int = 3
const AUTOSAVE_DAYS: int = 60

static func autosave_path(manual_path: String, slot: int) -> String:
	return manual_path.get_base_dir().path_join("autosave%d.json" % slot)

static func autosave_index_path(manual_path: String) -> String:
	return manual_path.get_base_dir().path_join("autosave.index")

## Slot named in the index (1-3), or 0 when it is missing or invalid.
func last_autosave_slot(manual_path: String) -> int:
	var index_path: String = autosave_index_path(manual_path)
	if not files.exists(index_path): return 0
	var read: Dictionary = files.read_text(index_path)
	if not read.ok: return 0
	var text: String = String(read.text).strip_edges()
	if not text.is_valid_int(): return 0
	var slot: int = text.to_int()
	return slot if slot >= 1 and slot <= AUTOSAVE_SLOTS else 0

func has_autosave(manual_path: String) -> bool:
	for slot in range(1, AUTOSAVE_SLOTS + 1):
		if files.exists(autosave_path(manual_path, slot)): return true
	return false

func next_autosave_slot(manual_path: String) -> int:
	var last: int = last_autosave_slot(manual_path)
	if last > 0: return last % AUTOSAVE_SLOTS + 1
	for slot in range(1, AUTOSAVE_SLOTS + 1):
		if not files.exists(autosave_path(manual_path, slot)): return slot
	return 1

func save_autosave(city: City, manual_path: String) -> Dictionary:
	var slot: int = next_autosave_slot(manual_path)
	var path: String = autosave_path(manual_path, slot)
	var text: String = JSON.stringify(city.snapshot(), "", true)
	if not Codec.decode(text).ok:
		return Codec.fail("Autosave skipped: the city could not be validated. Your manual save is unchanged.")
	var pending: String = path + ".tmp"
	var err: Error = files.write_text(pending, text)
	if err != OK:
		return Codec.fail("Autosave failed (%s). Your manual save is unchanged." % error_string(err))
	var readback: Dictionary = load_city(pending)
	if not readback.ok or readback.city.canonical() != city.canonical():
		return Codec.fail("Autosave verification failed. Your manual save is unchanged.")
	err = files.replace_file(pending, path)
	if err != OK:
		return Codec.fail("Autosave failed (%s). Your manual save is unchanged." % error_string(err))
	var index_path: String = autosave_index_path(manual_path)
	err = files.write_text(index_path + ".tmp", str(slot))
	if err == OK: err = files.replace_file(index_path + ".tmp", index_path)
	return {"ok": true, "slot": slot, "path": path, "message": "Autosaved (slot %d of %d)." % [slot, AUTOSAVE_SLOTS]}

## Newest valid autosave: from the index slot backwards; without an index, the valid
## slot with the latest date (then the highest slot). Adds "slot" to the load result.
func load_autosave(manual_path: String) -> Dictionary:
	var last: int = last_autosave_slot(manual_path)
	var order: Array[int] = []
	if last > 0:
		for k in range(AUTOSAVE_SLOTS): order.append(posmod(last - 1 - k, AUTOSAVE_SLOTS) + 1)
	else:
		var best: Dictionary = {}
		for slot in range(AUTOSAVE_SLOTS, 0, -1):
			var path: String = autosave_path(manual_path, slot)
			if not files.exists(path): continue
			var result: Dictionary = load_city(path)
			if result.ok and (best.is_empty() or result.city.tick > best.city.tick):
				best = result
				best["slot"] = slot
		return best if not best.is_empty() else Codec.fail("No valid autosave yet.")
	for slot in order:
		var path: String = autosave_path(manual_path, slot)
		if not files.exists(path): continue
		var result: Dictionary = load_city(path)
		if result.ok:
			result["slot"] = slot
			return result
	return Codec.fail("No valid autosave yet.")
