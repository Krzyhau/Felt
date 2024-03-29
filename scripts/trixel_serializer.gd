class_name TrixelSerializer extends Resource

var triles : Array
var loaded : bool
var last_error : String

var meshes : Dictionary
var json

func deserialize_from(json_path : String):
	
	var filebulk_path := json_path.substr(0, json_path.length() - ".json".length())
	
	var file_datas := _open_data_files(filebulk_path)
	if not _validate_data_files(file_datas): return
	
	var gen_start_time = Time.get_ticks_usec()
	
	var obj_text = file_datas["OBJ"].get_as_text(true)
	meshes = ObjSerializer.deserialize_from(obj_text)
	
	var gen_end_time = Time.get_ticks_usec()
	var gen_time = (gen_end_time-gen_start_time)/1000.0
	var gen_time_str = ("%.3f ms" % gen_time)
	print("obj deserialization - %s" % gen_time_str)
	
	triles = []
	
	json = JSON.parse_string(file_datas["JSON"].get_as_text(true))
	
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
