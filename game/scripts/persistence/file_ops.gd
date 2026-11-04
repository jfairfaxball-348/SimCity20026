extends RefCounted
## Small storage boundary, also used by failure-injection tests.
const Codec = preload("res://scripts/persistence/save_codec.gd")

func exists(path: String) -> bool:
	return FileAccess.file_exists(path)

func read_text(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return Codec.fail("Cannot open save: %s." % error_string(FileAccess.get_open_error()))
	if file.get_length() > Codec.MAX_BYTES:
		return Codec.fail("Save file is too large.")
	var text: String = file.get_as_text()
	file.close()
	return {"ok": true, "text": text}

func write_text(path: String, text: String) -> Error:
	var err: Error = DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if err != OK:
		return err
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(text)
	file.flush()
	err = file.get_error()
	file.close()
	return err

func copy_file(from: String, to: String) -> Error:
	return DirAccess.copy_absolute(from, to)

func replace_file(from: String, to: String) -> Error:
	return DirAccess.rename_absolute(from, to)
