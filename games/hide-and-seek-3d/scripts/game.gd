extends Node3D

const MallBuilder = preload("res://scripts/mall_builder.gd")
const PlayerController = preload("res://scripts/player.gd")
const HunterController = preload("res://scripts/hunter.gd")

const PREP_TIME := 12.0
const ROUND_TIME := 150.0

var player: HideAndSeekPlayer
var hunter: MallHunter
var mall: AbandonedMallBuilder
var round_phase := "prepare"
var phase_time := PREP_TIME
var finished := false
var round_active := false
var disguised := false
var disguise_visual: Node3D
var hud_timer: Label
var hud_status: Label
var hud_hint: Label
var screen_layer: CanvasLayer

func _ready() -> void:
	_build_world()
	_spawn_characters()
	_build_hud()
	_build_main_menu()

func _build_world() -> void:
	mall = MallBuilder.new()
	mall.name = "AbandonedShoppingMall"
	add_child(mall)
	mall.build()

func _spawn_characters() -> void:
	player = PlayerController.new()
	player.name = "Survivor"
	player.position = Vector3(-23.0, 0.1, 17.0)
	player.interact_callback = Callable(self, "_toggle_disguise")
	add_child(player)
	player.set_physics_process(false)
	player.set_process_input(false)
	var touch_controls := player.get_node_or_null("TouchControls")
	if touch_controls:
		touch_controls.visible = false

	hunter = HunterController.new()
	hunter.name = "MallHunter"
	hunter.position = Vector3(23.0, 0.1, -17.0)
	hunter.set_physics_process(false)
	hunter.target = player
	hunter.caught_survivor.connect(_on_player_caught)
	add_child(hunter)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "GameHUD"
	layer.layer = 5
	add_child(layer)

	var panel := PanelContainer.new()
	panel.position = Vector2(22, 18)
	panel.custom_minimum_size = Vector2(420, 116)
	layer.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)

	hud_timer = Label.new()
	hud_timer.add_theme_font_size_override("font_size", 25)
	hud_timer.add_theme_color_override("font_color", Color("#f3d16b"))
	column.add_child(hud_timer)

	hud_status = Label.new()
	hud_status.add_theme_font_size_override("font_size", 17)
	hud_status.add_theme_color_override("font_color", Color("#e4e6df"))
	column.add_child(hud_status)

	hud_hint = Label.new()
	hud_hint.text = "WASD — движение  •  E — маскировка  •  мышь — обзор  •  Esc — пауза"
	hud_hint.add_theme_font_size_override("font_size", 14)
	hud_hint.add_theme_color_override("font_color", Color("#aeb8b8"))
	column.add_child(hud_hint)

	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-7, -13)
	crosshair.add_theme_font_size_override("font_size", 25)
	crosshair.add_theme_color_override("font_color", Color(1, 0.91, 0.66, 0.8))
	layer.add_child(crosshair)

func _build_main_menu() -> void:
	_show_screen(
		"OTKAT  |  HIDE & SEEK",
		"ЗАБРОШЕННЫЙ ТОРГОВЫЙ ЦЕНТР\n\nТы — выживший. У тебя 12 секунд, чтобы спрятаться среди предметов. Затем охотник начнёт патрулировать и искать тебя. Продержись 150 секунд!",
		[
			{"text": "НАЧАТЬ ИГРУ", "action": Callable(self, "_start_round")},
			{"text": "КАК ИГРАТЬ", "action": Callable(self, "_show_controls_help")}
		]
	)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _show_screen(title_text: String, body_text: String, buttons: Array) -> void:
	if is_instance_valid(screen_layer):
		screen_layer.queue_free()
	screen_layer = CanvasLayer.new()
	screen_layer.name = "MenuOverlay"
	screen_layer.layer = 20
	add_child(screen_layer)

	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.02, 0.028, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_layer.add_child(shade)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-260, -220)
	panel.custom_minimum_size = Vector2(520, 440)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#171d22")
	panel_style.border_color = Color("#d7ae42")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(12)
	panel_style.content_margin_left = 28
	panel_style.content_margin_right = 28
	panel_style.content_margin_top = 26
	panel_style.content_margin_bottom = 26
	panel.add_theme_stylebox_override("panel", panel_style)
	screen_layer.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("#f3d16b"))
	column.add_child(title)

	var body := Label.new()
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 17)
	body.add_theme_color_override("font_color", Color("#e2e4df"))
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)

	for item in buttons:
		var button := Button.new()
		button.text = str(item["text"])
		button.custom_minimum_size = Vector2(0, 54)
		button.add_theme_font_size_override("font_size", 18)
		button.pressed.connect(item["action"])
		column.add_child(button)

func _show_controls_help() -> void:
	_show_screen(
		"УПРАВЛЕНИЕ",
		"КОМПЬЮТЕР\nWASD или стрелки — движение. Мышь — обзор. E — спрятаться или выйти из маскировки. Esc — пауза. R — новый раунд после завершения.\n\nANDROID\nЛевая половина экрана — движение. Правая половина — обзор. Кнопка «Маскировка» — спрятаться или выйти.\n\nЦЕЛЬ\nНайди предмет для маскировки до конца подготовки. Охотник может заметить тебя, если подойдёт близко. Переживи 150 секунд.",
		[{"text": "НАЗАД", "action": Callable(self, "_build_main_menu")}]
	)

func _start_round() -> void:
	if is_instance_valid(screen_layer):
		screen_layer.queue_free()
	screen_layer = null
	finished = false
	round_active = true
	round_phase = "prepare"
	phase_time = PREP_TIME
	disguised = false
	if is_instance_valid(disguise_visual):
		disguise_visual.queue_free()
	player.global_position = Vector3(-23.0, 0.1, 17.0)
	player.set_disguised(false)
	player.set_physics_process(true)
	player.set_process_input(true)
	var touch_controls := player.get_node_or_null("TouchControls")
	if touch_controls:
		touch_controls.visible = true
	hunter.global_position = Vector3(23.0, 0.1, -17.0)
	hunter.state = "patrol"
	hunter.patrol_index = 0
	hunter.set_physics_process(false)
	hud_hint.text = "WASD — движение  •  E — маскировка  •  Esc — пауза"
	hud_status.text = "Найди предмет и замаскируйся до выхода охотника."
	_update_hud()
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	if not round_active or finished:
		return
	phase_time -= delta
	if round_phase == "prepare" and phase_time <= 0.0:
		round_phase = "hunt"
		phase_time = ROUND_TIME
		hunter.set_physics_process(true)
		hud_status.text = "Охотник вышел на поиски. Продержись до конца!"
	elif round_phase == "hunt" and phase_time <= 0.0:
		_finish(true)
	_update_hud()

func _toggle_disguise() -> void:
	if not round_active or finished:
		return
	if disguised:
		_leave_disguise()
		return
	var point_index := _nearest_disguise_index()
	if point_index < 0:
		hud_status.text = "Подойди ближе к тележке, бочке, витрине или чемодану."
		return
	var anchor: Vector3 = mall.disguise_points[point_index]
	disguised = true
	player.set_disguised(true, anchor)
	_create_disguise_visual(anchor, point_index % 5)
	hud_status.text = "Ты замаскировался. Не двигайся и следи за охотником."

func _leave_disguise() -> void:
	disguised = false
	if is_instance_valid(disguise_visual):
		disguise_visual.queue_free()
	player.set_disguised(false)
	hud_status.text = "Ты вышел из маскировки. Найди новое укрытие!"

func _nearest_disguise_index() -> int:
	var best_index := -1
	var best_distance := 3.2
	for i in range(mall.disguise_points.size()):
		var distance := player.global_position.distance_to(mall.disguise_points[i])
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index

func _make_prop_part(parent: Node3D, part_name: String, size: Vector3, local_pos: Vector3, color: Color, cylinder: bool = false) -> void:
	var visual := MeshInstance3D.new()
	visual.name = part_name
	var mesh: Mesh
	if cylinder:
		var cylinder_mesh := CylinderMesh.new()
		cylinder_mesh.top_radius = size.x * 0.5
		cylinder_mesh.bottom_radius = size.x * 0.5
		cylinder_mesh.height = size.y
		mesh = cylinder_mesh
	else:
		var box_mesh := BoxMesh.new()
		box_mesh.size = size
		mesh = box_mesh
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	visual.material_override = material
	visual.position = local_pos
	parent.add_child(visual)

func _create_disguise_visual(anchor: Vector3, kind: int) -> void:
	if is_instance_valid(disguise_visual):
		disguise_visual.queue_free()
	disguise_visual = Node3D.new()
	disguise_visual.name = "PlayerDisguiseProp"
	disguise_visual.position = anchor
	add_child(disguise_visual)
	match kind:
		0:
			_make_prop_part(disguise_visual, "CartBasket", Vector3(1.1, 0.55, 0.7), Vector3(0, 0.08, 0), Color("#66716e"))
			_make_prop_part(disguise_visual, "CartBase", Vector3(1.0, 0.08, 0.65), Vector3(0, -0.27, 0), Color("#3e4847"))
			for x in [-0.42, 0.42]:
				for z in [-0.25, 0.25]:
					_make_prop_part(disguise_visual, "CartWheel", Vector3(0.16, 0.12, 0.12), Vector3(x, -0.42, z), Color("#252a2b"), true)
		1:
			_make_prop_part(disguise_visual, "BarrelBody", Vector3(0.92, 1.15, 0.92), Vector3(0, 0.08, 0), Color("#77624b"), true)
			for y in [-0.28, 0.28]:
				_make_prop_part(disguise_visual, "BarrelBand", Vector3(0.98, 0.07, 0.98), Vector3(0, y, 0), Color("#343b3a"), true)
		2:
			_make_prop_part(disguise_visual, "DisplayBase", Vector3(1.2, 1.15, 0.8), Vector3(0, 0.08, 0), Color("#726653"))
			_make_prop_part(disguise_visual, "DisplayTop", Vector3(1.28, 0.12, 0.88), Vector3(0, 0.7, 0), Color("#4a5c5d"))
		3:
			_make_prop_part(disguise_visual, "PlanterPot", Vector3(1.25, 0.72, 1.25), Vector3(0, -0.08, 0), Color("#5d5548"), true)
			_make_prop_part(disguise_visual, "PlanterFoliage", Vector3(0.95, 0.55, 0.95), Vector3(0, 0.48, 0), Color("#435b42"), true)
		_:
			_make_prop_part(disguise_visual, "SuitcaseBody", Vector3(0.85, 0.55, 0.48), Vector3(0, 0, 0), Color("#806448"))
			_make_prop_part(disguise_visual, "SuitcaseHandle", Vector3(0.32, 0.12, 0.08), Vector3(0, 0.34, 0), Color("#343638"))

func _on_player_caught() -> void:
	_finish(false)

func _finish(won: bool) -> void:
	if finished:
		return
	finished = true
	round_active = false
	player.set_physics_process(false)
	player.set_process_input(false)
	hunter.set_physics_process(false)
	var touch_controls := player.get_node_or_null("TouchControls")
	if touch_controls:
		touch_controls.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var result_title := "ПОБЕДА!" if won else "ТЕБЯ НАШЛИ"
	var result_body := "Ты пережил всю охоту и выбрался из торгового центра." if won else "Охотник обнаружил твою маскировку. Попробуй другую точку и следи за его маршрутом."
	_show_screen(
		result_title,
		result_body,
		[
			{"text": "ИГРАТЬ ЕЩЁ РАЗ", "action": Callable(self, "_start_round")},
			{"text": "В ГЛАВНОЕ МЕНЮ", "action": Callable(self, "_build_main_menu")}
		]
	)

func _pause_round() -> void:
	if not round_active or finished:
		return
	round_active = false
	player.set_physics_process(false)
	player.set_process_input(false)
	hunter.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_screen(
		"ПАУЗА",
		"Раунд приостановлен. Текущее время и положение сохранены.",
		[
			{"text": "ПРОДОЛЖИТЬ", "action": Callable(self, "_resume_round")},
			{"text": "ЗАНОВО", "action": Callable(self, "_start_round")},
			{"text": "В ГЛАВНОЕ МЕНЮ", "action": Callable(self, "_build_main_menu")}
		]
	)

func _resume_round() -> void:
	if is_instance_valid(screen_layer):
		screen_layer.queue_free()
	screen_layer = null
	round_active = true
	player.set_physics_process(true)
	player.set_process_input(true)
	hunter.set_physics_process(round_phase == "hunt")
	var touch_controls := player.get_node_or_null("TouchControls")
	if touch_controls:
		touch_controls.visible = true
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if round_active:
				_pause_round()
			elif not finished and is_instance_valid(screen_layer):
				_build_main_menu()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_R and finished:
			_start_round()

func _update_hud() -> void:
	if not is_instance_valid(hud_timer) or not round_active:
		return
	var prefix := "ПОДГОТОВКА" if round_phase == "prepare" else "ОХОТА"
	hud_timer.text = "%s  •  %03d" % [prefix, int(ceil(maxf(phase_time, 0.0)))]
