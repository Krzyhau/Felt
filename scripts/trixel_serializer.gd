class_name TrixelSerializer extends Resource

var loaded : bool
var last_error : String

var triles : Dictionary
var data : Dictionary

func deserialize_from(json_path : String):
	
	var filebulk_path := json_path.substr(0, json_path.length() - ".json".length())
	
	var file_datas := _open_data_files(filebulk_path)
	if not _validate_data_files(file_datas): return
	
	if filebulk_path.ends_with("fezao"):
		_parse_art_object(file_datas)
	elif filebulk_path.ends_with("fezts"):
		_parse_trile_set(file_datas)
	
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

func _deserialize_meshes(obj : FileAccess) -> Dictionary:
	var gen_start_time = Time.get_ticks_usec()
	
	var obj_text = obj.get_as_text(true)
	var meshes := ObjSerializer.deserialize_from(obj_text)
	
	var gen_end_time = Time.get_ticks_usec()
	var gen_time = (gen_end_time-gen_start_time)/1000.0
	var gen_time_str = ("%.3f ms" % gen_time)
	print("obj deserialization - %s" % gen_time_str)
	return meshes

func _parse_art_object(file_datas : Dictionary):
	var meshes = _deserialize_meshes(file_datas["OBJ"])
	var properties : Dictionary = JSON.parse_string(file_datas["JSON"].get_as_text(true))
	
	var size_array = properties["Size"]
	var size := Vector3(size_array[0], size_array[1], size_array[2])
	var trile := Trile.new(size)
	
	trile.set_raw_mesh(meshes.values()[0])
	
	triles[0] = trile
	
func _parse_trile_set(file_datas : Dictionary):
	var meshes = _deserialize_meshes(file_datas["OBJ"])
	var properties : Dictionary = JSON.parse_string(file_datas["JSON"].get_as_text(true))
	
	for trile_id in properties["Triles"].keys():
		if not meshes.has(trile_id): continue
		
		var size_array = properties["Triles"][trile_id]["Size"]
		var size := Vector3(size_array[0], size_array[1], size_array[2])
		
		var trile := Trile.new(size)
		trile.set_raw_mesh(meshes[trile_id])
		triles[trile_id] = trile
