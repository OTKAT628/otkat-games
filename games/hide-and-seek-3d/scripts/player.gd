extends CharacterBody3D
class_name HideAndSeekPlayer

signal disguise_changed(active: bool)
signal player_caught

const WALK_SPEED := 5.2
const MOUSE_SENSITIVITY := 0.0024
const TOUCH_LOOK_SENSITIVITY := 0.004
const GRAVITY := 18.0

var camera_pivot: Node3D
var camera: Camera3D
var disguised := false
var disguise_anchor := Vector3.ZERO
var touch_move := Vector2.ZERO
var move_touch_id := -1
var look_touch_id := -1
var last_look_position := Vector2.ZERO
var mobile_button: Button
var interact_callback: Callable

func _ready() -> void:
	_build_body()
	_build_camera()
	_build_mobile_controls()
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_body() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.75
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)

	var body_mesh := MeshInstance3D.new()
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.radius = 0.34
	capsule_mesh.height = 1.7
	body_mesh.mesh = capsule_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#e8bf57")
	mat.roughness = 0.72
	body_mesh.material_override = mat
	body_mesh.position.y = 0.9
	body_mesh.name = "SurvivorVisual"
	add_child(body_mesh)

func _build_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.position.y = 1.58
	add_child(camera_pivot)
	camera = Camera3D.new()
	camera.fov = 78.0
	camera.current = true
	camera.position = Vector3(0, 0, 0)
	camera_pivot.add_child(camera)

func _build_mobile_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "TouchControls"
	add_child(layer)
	var hint := Label.new()
	hint.text = "ЛЕВАЯ СТОРОНА — ДВИЖЕНИЕ   •   ПРАВАЯ — ОБЗОР"
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.92, 0.9, 0.82, 0.72))
	hint.anchor_left = 0.0
	hint.anchor_top = 1.0
	hint.anchor_right = 0.0
	hint.anchor_bottom = 1.0
	hint.position = Vector2(26, -48)
	layer.add_child(hint)

	mobile_button = Button.new()
	mobile_button.text = "МАСКИРОВКА  [E]"
	mobile_button.custom_minimum_size = Vector2(190, 64)
	mobile_button.anchor_left = 1.0
	mobile_button.anchor_top = 1.0
	mobile_button.anchor_right = 1.0
	mobile_button.anchor_bottom = 1.0
	mobile_button.position = Vector2(-218, -112)
	mobile_button.add_theme_font_size_override("font_size", 18)
	mobile_button.pressed.connect(_on_interact_pressed)
	layer.add_child(mobile_button)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_rotate_view(event.relative, MOUSE_SENSITIVITY)
	elif event is InputEventScreenTouch:
		var width := get_viewport().get_visible_rect().size.x
		if event.pressed:
			if event.position.x < width * 0.48 and move_touch_id == -1:
				move_touch_id = event.index
				touch_move = Vector2.ZERO
			elif event.position.x >= width * 0.48 and look_touch_id == -1:
				look_touch_id = event.index
				last_look_position = event.position
		else:
			if event.index == move_touch_id:
				move_touch_id = -1
				touch_move = Vector2.ZERO
			if event.index == look_touch_id:
				look_touch_id = -1
	elif event is InputEventScreenDrag:
		if event.index == move_touch_id:
			touch_move = (event.position - Vector2(150, get_viewport().get_visible_rect().size.y - 150)).limit_length(90.0) / 90.0
			touch_move.y = -touch_move.y
		elif event.index == look_touch_id:
			_rotate_view(event.relative, TOUCH_LOOK_SENSITIVITY)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			_on_interact_pressed()
		elif event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _rotate_view(delta: Vector2, sensitivity: float) -> void:
	rotate_y(-delta.x * sensitivity)
	camera_pivot.rotation.x = clampf(camera_pivot.rotation.x - delta.y * sensitivity, -1.25, 1.25)

func _physics_process(delta: float) -> void:
	if disguised:
		velocity = Vector3.ZERO
		return
	var input_vector := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_vector.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_vector.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_vector.y += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_vector.y -= 1.0
	input_vector += touch_move
	input_vector = input_vector.limit_length(1.0)
	var direction := (global_transform.basis * Vector3(input_vector.x, 0, -input_vector.y)).normalized()
	velocity.x = direction.x * WALK_SPEED
	velocity.z = direction.z * WALK_SPEED
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.2
	move_and_slide()

func _on_interact_pressed() -> void:
	if interact_callback.is_valid():
		interact_callback.call()

func set_disguised(active: bool, anchor: Vector3 = Vector3.ZERO) -> void:
	disguised = active
	disguise_anchor = anchor
	var visual := get_node_or_null("SurvivorVisual") as MeshInstance3D
	if visual:
		visual.visible = not active
	if active:
		global_position = anchor
	disguise_changed.emit(active)

func get_camera_direction() -> Vector3:
	return -camera.global_transform.basis.z
