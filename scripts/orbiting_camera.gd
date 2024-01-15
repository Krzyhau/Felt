extends Node3D

@export var minimum_zoom_distance: float
@export var maximum_zoom_distance: float
@export var scroll_zoom_scale: float
@export var zoom_distance_interpolation: float
@export var orbiting_scale: float
@export var transition_time: float

var _zoom_distance : float
var _orbiting : bool
var _panning : bool
var _transitioning : bool
var _panning_initial_mouse : Vector3
var _panning_current_mouse : Vector3
var _orbiting_initial_mouse : Vector2
var _orbiting_current_mouse: Vector2
var _orbiting_initial_rotation : Vector3

var _transition_tween : Tween;
var _fov_original : float;

var camera : Camera3D

func _ready():
	camera = $camera3d as Camera3D
	_zoom_distance = camera.position.z
	_fov_original = camera.fov

func _input(event):
	_input_zooming(event)
	_input_orbiting(event)
	_input_panning(event)
	
	if Input.is_action_just_pressed("camera_recenter"): recenter()
	if Input.is_action_just_pressed("camera_switch_ortho"): switch_ortho()
	
	if Input.is_action_just_pressed("camera_snap_left"): snap(0, -1)
	if Input.is_action_just_pressed("camera_snap_right"): snap(0, 1)
	if Input.is_action_just_pressed("camera_snap_up"): snap(-1, 0)
	if Input.is_action_just_pressed("camera_snap_down"): snap(1, 0)


func _input_zooming(event):
	if _transitioning: return;
	
	if Input.is_action_just_released("zoom_in"):
		_zoom_distance /= scroll_zoom_scale
		
	if Input.is_action_just_released("zoom_out"):
		_zoom_distance *= scroll_zoom_scale

	_zoom_distance = clamp(_zoom_distance, minimum_zoom_distance, maximum_zoom_distance)

func _input_orbiting(event):
	if event is InputEventMouseButton:
		if event.button_index != 2: return
		_orbiting = event.pressed
		_orbiting_initial_mouse = event.position
		_orbiting_current_mouse = event.position
		_orbiting_initial_rotation = rotation_degrees
	if event is InputEventMouseMotion:
		_orbiting_current_mouse = event.position


func _input_panning(event):
	if not event is InputEventMouse: return
	
	var pan_pos = camera.project_position(event.position, _zoom_distance)
	
	if event is InputEventMouseButton:
		if event.button_index != 3: return
		_panning = event.pressed
		_panning_initial_mouse = pan_pos
	if _panning:
		_panning_current_mouse = pan_pos



func _process(delta:float):
	_handle_zooming(delta)
	_handle_orbiting(delta)
	_handle_panning(delta)


func _handle_zooming(delta:float):
	if not _transitioning: 
		var zpos = lerp(camera.position.z, _zoom_distance, zoom_distance_interpolation * delta)
		_set_camera_distance(zpos)


func _set_camera_distance(value:float):
	camera.position.z = value;
	
	# for seamless transition between persp and ortho
	const ortho_zoom_scale = 1.5 
	camera.size = value * ortho_zoom_scale


func _handle_orbiting(delta:float):
	if _orbiting:
		var mouse_diff = (_orbiting_current_mouse - _orbiting_initial_mouse) * orbiting_scale
		var new_rot = _orbiting_initial_rotation + Vector3(-mouse_diff.y, -mouse_diff.x, 0.0)
		new_rot.x = clamp(new_rot.x, -90.0, 90.0)
		
		rotation_degrees = new_rot


func _handle_panning(delta:float):
	if _panning:
		position -= (_panning_current_mouse - _panning_initial_mouse)


func _fake_projection_lerp_apply(state:float, initial_zoom_distance:float):
	state = pow(state, 3)
	
	var minFov = 1.1 # godot throws an error when camera fov < 1.0
	var maxDist = (camera.size * 0.5) / tan(deg_to_rad(minFov * 0.5))
	
	camera.position.z = initial_zoom_distance + lerp(0.0, maxDist, state)
	camera.fov = rad_to_deg(atan2(camera.size * 0.5, camera.position.z)) * 2.0


func _initialize_or_restart_transition():
	if _transition_tween: _transition_tween.kill()
	_transition_tween = get_tree().create_tween()
	_transition_tween.set_parallel(true)
	_transitioning = true


func transition(target_pos:Vector3, target_quat:Quaternion, projection:Camera3D.ProjectionType):
	_initialize_or_restart_transition()
	
	_transition_tween.set_trans(Tween.TRANS_SINE)
	_transition_tween.tween_property(self, "position", target_pos, transition_time)
	_transition_tween.tween_property(self, "quaternion", target_quat, transition_time)
	
	if camera.projection != projection:
		var reverse = (projection == camera.PROJECTION_PERSPECTIVE)
		var projection_lerp_bind = _fake_projection_lerp_apply.bind(camera.position.z)
		var from = 1.0 if reverse else 0.0
		var to = 0.0 if reverse else 1.0
		_transition_tween.set_trans(Tween.TRANS_LINEAR)
		_transition_tween.tween_method(projection_lerp_bind, from, to, transition_time)
		if reverse: camera.projection = projection
	
	_transition_tween.set_parallel(false)
	_transition_tween.tween_callback(func(): 
		_transitioning = false
		camera.projection = projection
		_set_camera_distance(_zoom_distance)
		camera.fov = _fov_original
	)


func recenter():
	transition(Vector3.ZERO, quaternion, camera.projection)


func switch_ortho():
	var projection : Camera3D.ProjectionType;
	match camera.projection:
		camera.PROJECTION_PERSPECTIVE: projection = camera.PROJECTION_ORTHOGONAL
		camera.PROJECTION_ORTHOGONAL: projection = camera.PROJECTION_PERSPECTIVE
		
	transition(position, quaternion, projection)


func snap(pitch_dir:int, yaw_dir:int):
	var angle_delta = Vector3(pitch_dir, yaw_dir, 0.0) * 45.0
	
	var new_angles = rotation_degrees + angle_delta
	new_angles.x = clamp(new_angles.x, -90.0, 90.0)
	
	const increment = 45.0
	new_angles = round(new_angles / increment) * increment
	
	var new_angles_rad = Vector3(deg_to_rad(new_angles.x), deg_to_rad(new_angles.y), 0.0)
	var new_rot = Quaternion.from_euler(new_angles_rad)
	
	transition(position, new_rot, camera.projection)
