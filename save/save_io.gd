extends RefCounted
class_name SaveIO

const SAVE_VERSION := 1
const SAVE_DIR := "user://saves"
const DEFAULT_SLOT := "autosave.save"

static func get_slot_path(slot_name: String = DEFAULT_SLOT) -> String:
	return "%s/%s" % [SAVE_DIR, slot_name]

static func ensure_save_directory() -> void:
	if DirAccess.dir_exists_absolute(SAVE_DIR):
		return
	var err := DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	if err != OK:
		push_error("Unable to create save directory %s (error %s)" % [SAVE_DIR, err])

static func write_slot(payload: Dictionary, slot_name: String = DEFAULT_SLOT) -> Error:
	ensure_save_directory()
	var path := get_slot_path(slot_name)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_var(payload, true)
	file.flush()
	file.close()
	return OK

static func load_slot(slot_name: String = DEFAULT_SLOT) -> Dictionary:
	ensure_save_directory()
	var path := get_slot_path(slot_name)
	if !FileAccess.file_exists(path):
		return {"ok": false, "error": "missing"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "open_failed_%s" % FileAccess.get_open_error()}
	var error_msg := ""
	var ok := true
	var data := {}
	if file.get_length() == 0:
		ok = false
		error_msg = "empty_file"
	else:
		file.seek(0)
		data = file.get_var(true)
		var err := file.get_error()
		if err != OK and err != ERR_FILE_EOF:
			ok = false
			error_msg = "corrupt_%s" % err
	file.close()
	if ok:
		return {"ok": true, "data": data}
	return {"ok": false, "error": error_msg}

static func slot_exists(slot_name: String = DEFAULT_SLOT) -> bool:
	ensure_save_directory()
	return FileAccess.file_exists(get_slot_path(slot_name))

static func delete_slot(slot_name: String = DEFAULT_SLOT) -> void:
	ensure_save_directory()
	var path := get_slot_path(slot_name)
	if FileAccess.file_exists(path):
		var err := DirAccess.remove_absolute(path)
		if err != OK:
			push_warning("Failed to delete save slot %s (error %s)" % [path, err])
