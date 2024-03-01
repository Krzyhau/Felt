class_name TrixelSerializer extends Resource

var triles : Array
var loaded : bool
var last_error : String

func deserialize_from(json_path : String):
	
	var filebulk_path := json_path.substr(0, json_path.length() - ".json".length())
	
	var file_datas := _open_data_files(filebulk_path)
	if not _validate_data_files(file_datas): return
	
	
	
	triles = []
	
	
	loaded = true


func _open_data_files(filebulk_path : String) -> Dictionary:
	var files = Dictionary()
	
	files["JSON"] = FileAccess.open(filebulk_path + ".json", FileAccess.READ)
	files["OBJ"] = FileAccess.open(filebulk_path + ".obj", FileAccess.READ)
	files["PNG"] = FileAccess.open(filebulk_path + ".png", FileAccess.READ)
	files["APNG"] = FileAccess.open(filebulk_path + ".apng", FileAccess.READ)

	return files

func _validate_data_files(file_datas : Dictionary) -> bool:
	for name in ["JSON", "OBJ", "PNG"]:
		if not file_datas.has(name) or file_datas[name] == null:
			last_error = "Cannot open required %s file" % name
			return false
	return true
