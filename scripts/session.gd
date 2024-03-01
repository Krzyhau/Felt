class_name FeltSession extends Node

@export var trile_editor : TrileEditor

@export var open_discard_dialog : ConfirmationDialog
@export var exit_discard_dialog : ExitDiscardDialog
@export var open_file_dialog : FileDialog

var dirty : bool

var save_quitting : bool

func _ready() -> void:
	dirty = false
	open_discard_dialog.confirmed.connect(_show_open_file_dialog)
	open_file_dialog.file_selected.connect(open_file)
	exit_discard_dialog.save_ignored.connect(_quit)
	exit_discard_dialog.save_requested.connect(try_save_quit)

func try_open_file():
	if dirty: open_discard_dialog.visible = true
	else: _show_open_file_dialog()

func try_quit():
	if dirty: exit_discard_dialog.visible = true
	else: _quit()

func try_save_quit():
	save_quitting = true
	try_save()

func try_save():
	if not dirty: return
	pass

func open_file(path : String):
	var serializer = TrixelSerializer.new()
	serializer.deserialize_from(path)
	
	var trile = trile_editor.trile
	trile.clear_surfaces()
	trile.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, serializer.meshes[serializer.meshes.keys()[0]])
	trile.surface_set_material(0, trile.material)

func _show_open_file_dialog():
	open_file_dialog.visible = true

func _quit():
	get_tree().quit()
