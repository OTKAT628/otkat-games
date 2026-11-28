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
var disguised := false
var disguise_visual: MeshInstance3D
var hud_timer: Label
var hud_status: Label
var hud_hint: Label

func _ready() -> void:
	_build_world()
	_spawn_characters()
	_build_hud()
	_update_hud()

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
	add_child(layer)

	var panel := PanelContainer.new()
	panel.position = Vector2(22, 18)
	panel.custom_minimum_size = Vector2(410, 112)
	layer.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)

	hud_timer = Label.new()
	hud_timer.add_theme_font_size_override("font_size", 24)
	hud_timer.add_theme_color_override("font_color", Color("#f3d16b"))
	column.add_child(hud_timer)

	hud_status = Label.new()
	hud_status.add_theme_font_size_override("font_size", 17)
	hud_status.add_theme_color_override("font_color", Color("#e4e6df"))
	column.add_child(hud_status)

	hud_hint = Label.new()
	hud_hint.text = "WASD — движение  •  E — маскировка  •  мышь — обзор"
	hud_hint.add_theme_font_size_override("font_size", 14)
	hud_hint.add_theme_color_override("font_color", Color("#aeb8b8"))
	column.add_child(hud_hint)

func _process(delta: float) -> void:
	if finished:
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
	if finished:
		return
	if disguised:
		_leave_disguise()
		return
	var anchor := _nearest_disguise_point()
	if anchor == Vector3.INF:
		hud_status.text = "Подойди ближе к тележке, ящику или другому предмету."
		return
	disguised = true
	player.set_disguised(true, anchor)
	_create_disguise_visual(anchor)
	hud_status.text = "Ты замаскировался. Не двигайся и следи за охотником."

func _leave_disguise() -> void:
	disguised = false
	if is_instance_valid(disguise_visual):
		disguise_visual.queue_free()
	player.set_disguised(false)
	hud_status.text = "Ты вышел из маскировки. Найди новое укрытие!"

func _nearest_disguise_point() -> Vector3:
	var best := Vector3.INF
	var best_distance := 3.2
	for point in mall.disguise_points:
		var distance := player.global_position.distance_to(point)
		if distance < best_distance:
			best_distance = distance
			best = point
	return best

func _create_disguise_visual(anchor: Vector3) -> void:
	if is_instance_valid(disguise_visual):
		disguise_visual.queue_free()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.9, 1.0, 0.65)
	disguise_visual = MeshInstance3D.new()
	disguise_visual.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#85745d")
	mat.roughness = 0.9
	disguise_visual.material_override = mat
	disguise_visual.position = anchor
	add_child(disguise_visual)

func _on_player_caught() -> void:
	_finish(false)

func _finish(won: bool) -> void:
	finished = true
	player.set_physics_process(false)
	hunter.set_physics_process(false)
	hud_status.text = "ПОБЕДА! Ты пережил охоту." if won else "ТЕБЯ НАШЛИ! Попробуй другую тактику."
	hud_hint.text = "Раунд завершён. Перезапуск — кнопка R."

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		get_tree().reload_current_scene()

func _update_hud() -> void:
	if not is_instance_valid(hud_timer):
		return
	var prefix := "ПОДГОТОВКА" if round_phase == "prepare" else "ОХОТА"
	hud_timer.text = "%s  •  %03d" % [prefix, int(ceil(maxf(phase_time, 0.0)))]
	if round_phase == "prepare":
		hud_status.text = "У тебя 12 секунд, чтобы найти хорошую маскировку."
