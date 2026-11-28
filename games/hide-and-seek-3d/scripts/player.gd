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
var mouse_sensitivity := 0.0024
var touch_look_sensitivity := 0.004
const GRAVITY := 18.0

var camera_pivot: Node3D
var camera: Camera3D
var camera_mode_button: Button
var third_person := false
var body_collision: CollisionShape3D
var body_capsule: CapsuleShape3D
var body_visual: MeshInstance3D
var visual_capsule: CapsuleMesh
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
var fire_callback: Callable
var weapon_mount: Node3D
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
	body_collision = CollisionShape3D.new()
	body_capsule = CapsuleShape3D.new()
	body_capsule.radius = 0.36
	body_capsule.height = 1.75
	body_collision.shape = body_capsule
	body_collision.position.y = 0.9
	add_child(body_collision)

	body_visual = MeshInstance3D.new()
	visual_capsule = CapsuleMesh.new()
	visual_capsule.radius = 0.34
	visual_capsule.height = 1.7
	body_visual.mesh = visual_capsule
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#e8bf57")
	mat.roughness = 0.72
	body_visual.material_override = mat
	body_visual.position.y = 0.9
	body_visual.name = "SurvivorVisual"
	add_child(body_visual)
	_add_detail_box("FieldVest", Vector3(0.72, 0.72, 0.42), Vector3(0, 0.02, -0.015), Color("#b28a3d"))
	_add_detail_box("LeftShoulderPad", Vector3(0.28, 0.24, 0.42), Vector3(-0.34, 0.25, 0), Color("#d5b34e"))
	_add_detail_box("RightShoulderPad", Vector3(0.28, 0.24, 0.42), Vector3(0.34, 0.25, 0), Color("#d5b34e"))
	_add_detail_capsule("LeftArm", 0.13, 0.68, Vector3(-0.48, -0.03, 0), Color("#3f4947"))
	_add_detail_capsule("RightArm", 0.13, 0.68, Vector3(0.48, -0.03, 0), Color("#3f4947"))
	_add_detail_sphere("Head", 0.235, Vector3(0, 0.62, 0), Color("#b88d6b"))
	_add_detail_sphere("Helmet", 0.29, Vector3(0, 0.76, 0.015), Color("#d3ae42"))
	_add_detail_box("HelmetVisor", Vector3(0.34, 0.12, 0.035), Vector3(0, 0.67, -0.235), Color("#273c42"))
	_add_detail_box("Backpack", Vector3(0.46, 0.58, 0.24), Vector3(0, 0.04, 0.29), Color("#37433d"))
	_add_detail_box("ChestPatch", Vector3(0.22, 0.16, 0.025), Vector3(0, 0.2, -0.235), Color("#f0d56d"))

func _add_detail_box(part_name: String, size: Vector3, local_pos: Vector3, color: Color) -> void:
	var visual := MeshInstance3D.new()
	visual.name = part_name
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	visual.material_override = material
	visual.position = local_pos
	body_visual.add_child(visual)

func _add_detail_sphere(part_name: String, radius: float, local_pos: Vector3, color: Color) -> void:
	var visual := MeshInstance3D.new()
	visual.name = part_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	visual.material_override = material
	visual.position = local_pos
	body_visual.add_child(visual)

func _add_detail_capsule(part_name: String, radius: float, height: float, local_pos: Vector3, color: Color) -> void:
	var visual := MeshInstance3D.new()
	visual.name = part_name
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	visual.material_override = material
	visual.position = local_pos
	body_visual.add_child(visual)

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

	camera_mode_button = Button.new()
	camera_mode_button.text = "КАМЕРА  [V]"
	camera_mode_button.custom_minimum_size = Vector2(142, 48)
	camera_mode_button.anchor_left = 1.0
	camera_mode_button.anchor_top = 1.0
	camera_mode_button.anchor_right = 1.0
	camera_mode_button.anchor_bottom = 1.0
	camera_mode_button.position = Vector2(-152, -170)
	camera_mode_button.pressed.connect(toggle_camera_mode)
	layer.add_child(camera_mode_button)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_rotate_view(event.relative, mouse_sensitivity)
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
			_rotate_view(event.relative, touch_look_sensitivity)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if fire_callback.is_valid():
			fire_callback.call()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			_on_interact_pressed()
		elif event.keycode == KEY_V:
			toggle_camera_mode()
		elif event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _is_touch_ui_position(position: Vector2, viewport_size: Vector2) -> bool:
	if position.x <= 220.0 and position.y >= viewport_size.y - 132.0:
		return true
	if position.x >= viewport_size.x - 180.0 and position.y >= viewport_size.y - 190.0:
		return true
	if position.y <= 250.0 and position.x >= viewport_size.x - 340.0:
		return true
	return false

func toggle_camera_mode() -> void:
	third_person = not third_person
	if is_instance_valid(camera_mode_button):
		camera_mode_button.text = "КАМЕРА: 3-Е ЛИЦО" if third_person else "КАМЕРА: 1-Е ЛИЦО"
	if is_instance_valid(weapon_mount):
		weapon_mount.visible = not third_person
	if not third_person:
		camera.position = Vector3.ZERO
		camera.rotation = Vector3.ZERO
	else:
		camera.rotation = Vector3(-0.12, 0, 0)

func _update_third_person_camera() -> void:
	if not third_person:
		return
	var desired_local := Vector3(0, 0.3, 4.2)
	var from := camera_pivot.global_position
	var to := camera_pivot.to_global(desired_local)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		camera.position = desired_local
	else:
		camera.global_position = hit.position + hit.normal * 0.18
	camera.rotation = Vector3(-0.12, 0, 0)

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
	var wants_crouch := touch_crouch or Input.is_key_pressed(KEY_CTRL)
	if wants_crouch != is_crouching:
		is_crouching = wants_crouch
		_set_crouch_pose(is_crouching)
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
	_update_third_person_camera()

func _set_crouch_pose(active: bool) -> void:
	var capsule_height := 1.05 if active else 1.75
	body_capsule.height = capsule_height
	body_collision.position.y = capsule_height * 0.5
	body_visual.scale.y = capsule_height / 1.7
	body_visual.position.y = capsule_height * 0.5
	camera_pivot.position.y = 1.05 if active else 1.58

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
	if body_visual:
		body_visual.visible = not active
	disguise_changed.emit(active)

func get_camera_direction() -> Vector3:
	return -camera.global_transform.basis.z
