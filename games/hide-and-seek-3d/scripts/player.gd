extends CharacterBody3D
class_name HideAndSeekPlayer

signal disguise_changed(active: bool)
signal player_caught
signal noise_emitted(position: Vector3, radius: float)

const WALK_SPEED := 5.2
const SPRINT_SPEED := 7.4
const CROUCH_SPEED := 2.8
const STAMINA_DRAIN := 24.0
const STAMINA_REGEN := 16.0
const MOUSE_SENSITIVITY := 0.0024
const TOUCH_LOOK_SENSITIVITY := 0.004
const GRAVITY := 18.0

var camera_pivot: Node3D
var camera: Camera3D
var disguised := false
var disguise_anchor := Vector3.ZERO
var touch_move := Vector2.ZERO
var move_touch_id := -1
var move_touch_origin := Vector2.ZERO
var look_touch_id := -1
var last_look_position := Vector2.ZERO
var mobile_button: Button
var sprint_button: Button
var crouch_button: Button
var touch_sprint := false
var touch_crouch := false
var stamina := 100.0
var is_sprinting := false
var is_crouching := false
var noise_timer := 0.0
var interact_callback: Callable
var position_before_disguise := Vector3.ZERO
var saved_collision_layer := 1
var saved_collision_mask := 1

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
	layer.visible = OS.has_feature("mobile")

	mobile_button = Button.new()
	mobile_button.text = "МАСКИРОВКА  [E]"
	mobile_button.custom_minimum_size = Vector2(142, 58)
	mobile_button.anchor_left = 1.0
	mobile_button.anchor_top = 1.0
	mobile_button.anchor_right = 1.0
	mobile_button.anchor_bottom = 1.0
	mobile_button.position = Vector2(-152, -112)
	mobile_button.add_theme_font_size_override("font_size", 14)
	mobile_button.pressed.connect(_on_interact_pressed)
	layer.add_child(mobile_button)

	sprint_button = Button.new()
	sprint_button.text = "БЕГ"
	sprint_button.custom_minimum_size = Vector2(86, 58)
	sprint_button.anchor_left = 0.0
	sprint_button.anchor_top = 1.0
	sprint_button.anchor_right = 0.0
	sprint_button.anchor_bottom = 1.0
	sprint_button.position = Vector2(18, -112)
	sprint_button.button_down.connect(_on_sprint_down)
	sprint_button.button_up.connect(_on_sprint_up)
	layer.add_child(sprint_button)

	crouch_button = Button.new()
	crouch_button.text = "ПРИСЕСТЬ"
	crouch_button.custom_minimum_size = Vector2(90, 58)
	crouch_button.anchor_left = 0.0
	crouch_button.anchor_top = 1.0
	crouch_button.anchor_right = 0.0
	crouch_button.anchor_bottom = 1.0
	crouch_button.position = Vector2(112, -112)
	crouch_button.button_down.connect(_on_crouch_down)
	crouch_button.button_up.connect(_on_crouch_up)
	layer.add_child(crouch_button)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_rotate_view(event.relative, MOUSE_SENSITIVITY)
	elif event is InputEventScreenTouch:
		var viewport_size := get_viewport().get_visible_rect().size
		var width := viewport_size.x
		if event.pressed:
			if _is_touch_ui_position(event.position, viewport_size):
				return
			if event.position.x < width * 0.48 and move_touch_id == -1:
				move_touch_id = event.index
				move_touch_origin = event.position
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
			touch_move = (event.position - move_touch_origin).limit_length(90.0) / 90.0
			touch_move.y = -touch_move.y
		elif event.index == look_touch_id:
			_rotate_view(event.relative, TOUCH_LOOK_SENSITIVITY)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			_on_interact_pressed()
		elif event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _is_touch_ui_position(position: Vector2, viewport_size: Vector2) -> bool:
	if position.y >= viewport_size.y - 132.0:
		if position.x <= 220.0 or position.x >= viewport_size.x - 180.0:
			return true
	if position.y <= 190.0 and position.x >= viewport_size.x - 340.0:
		return true
	return false

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
	is_crouching = touch_crouch or Input.is_key_pressed(KEY_CTRL)
	is_sprinting = (touch_sprint or Input.is_key_pressed(KEY_SHIFT)) and not is_crouching and input_vector.length() > 0.1 and stamina > 0.5
	if is_sprinting:
		stamina = maxf(0.0, stamina - STAMINA_DRAIN * delta)
	else:
		stamina = minf(100.0, stamina + STAMINA_REGEN * delta)
	var move_speed := CROUCH_SPEED if is_crouching else (SPRINT_SPEED if is_sprinting else WALK_SPEED)
	var target_camera_height := 1.05 if is_crouching else 1.58
	camera_pivot.position.y = move_toward(camera_pivot.position.y, target_camera_height, delta * 3.0)
	var direction := (global_transform.basis * Vector3(input_vector.x, 0, -input_vector.y)).normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	if is_sprinting:
		noise_timer -= delta
		if noise_timer <= 0.0:
			noise_emitted.emit(global_position, 23.0)
			noise_timer = 0.85
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.2
	move_and_slide()

func _on_sprint_down() -> void:
	touch_sprint = true

func _on_sprint_up() -> void:
	touch_sprint = false

func _on_crouch_down() -> void:
	touch_crouch = true

func _on_crouch_up() -> void:
	touch_crouch = false

func _on_interact_pressed() -> void:
	if interact_callback.is_valid():
		interact_callback.call()

func set_disguised(active: bool, anchor: Vector3 = Vector3.ZERO) -> void:
	if active and not disguised:
		position_before_disguise = global_position
		saved_collision_layer = collision_layer
		saved_collision_mask = collision_mask
		disguise_anchor = anchor
		global_position = anchor - Vector3.UP * 0.5
		collision_layer = 0
		collision_mask = 0
	elif not active and disguised:
		global_position = position_before_disguise
		collision_layer = saved_collision_layer
		collision_mask = saved_collision_mask
	disguised = active
	var visual := get_node_or_null("SurvivorVisual") as MeshInstance3D
	if visual:
		visual.visible = not active
	disguise_changed.emit(active)

func get_camera_direction() -> Vector3:
	return -camera.global_transform.basis.z
