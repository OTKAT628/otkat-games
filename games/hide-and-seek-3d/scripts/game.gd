extends Node3D

const MallBuilder = preload("res://scripts/mall_builder.gd")
const PlayerController = preload("res://scripts/player.gd")
const HunterController = preload("res://scripts/hunter.gd")
const AbilityManager = preload("res://scripts/prop_abilities.gd")
const WeaponRuntime = preload("res://scripts/weapon_runtime.gd")
const ArsenalRegistry = preload("res://scripts/arsenal_registry.gd")
const InventoryManager = preload("res://scripts/cosmetic_inventory.gd")

const PREP_TIME := 12.0
const ROUND_TIME := 150.0
const SENSITIVITY_STEPS := [0.0016, 0.0024, 0.0032, 0.004]
const FOV_STEPS := [70.0, 78.0, 88.0]
var sensitivity_index := 1
var fov_index := 1

var player: HideAndSeekPlayer
var hunter: MallHunter
var abilities: OtkatPropAbilities
var weapon_runtime: OtkatWeaponRuntime
var inventory: OtkatCosmeticInventory
var mall: AbandonedMallBuilder
var total_wins := 0
var total_losses := 0
var selected_weapon_id := "ap_scout"
var ability_buttons: Array[Button] = []
var weapon_buttons: Array[Button] = []
var ammo_label: Label
var hunter_health_label: Label
var victory_message := "Ты пережил всю охоту и выбрался из торгового центра."
var pending_fire := false
var round_phase := "prepare"
var phase_time := PREP_TIME
var finished := false
var round_active := false
var disguised := false
var disguise_visual: Node3D
var hud_timer: Label
var hud_status: Label
var hud_hint: Label
var stamina_label: Label
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
	player.noise_emitted.connect(_on_player_noise)
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
	hunter.hunter_defeated.connect(_on_hunter_defeated)
	add_child(hunter)

	inventory = InventoryManager.new()
	if not inventory.owns_weapon("ap_scout"):
		inventory.unlock_weapon("ap_scout")
	if not inventory.owns_skin("ap_scout_tape"):
		inventory.unlock_skin("ap_scout_tape")
	inventory.equip_skin("ap_scout", "ap_scout_tape")
	_load_profile_stats()

	weapon_runtime = WeaponRuntime.new()
	weapon_runtime.name = "SurvivorWeapon"
	weapon_runtime.shooter = player
	weapon_runtime.position = Vector3(0.32, -0.25, -0.55)
	player.camera.add_child(weapon_runtime)
	player.weapon_mount = weapon_runtime
	player.fire_callback = Callable(self, "_fire_weapon")
	weapon_runtime.target_hit.connect(_on_weapon_hit)
	weapon_runtime.ammo_changed.connect(_on_ammo_changed)
	weapon_runtime.weapon_blocked.connect(_on_weapon_blocked)
	weapon_runtime.equip("apocalypse", selected_weapon_id, inventory.get_equipped_skin(selected_weapon_id))
	weapon_runtime.set_process(false)

	abilities = AbilityManager.new()
	abilities.name = "PropAbilities"
	abilities.set_process(false)
	add_child(abilities)
	abilities.decoy_created.connect(_on_decoy_created)
	abilities.hunter_frozen.connect(_on_hunter_frozen)
	abilities.hunter_bagged.connect(_on_hunter_bagged)
	abilities.ability_used.connect(_on_ability_used)
	abilities.ability_blocked.connect(_on_ability_blocked)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "GameHUD"
	layer.layer = 5
	add_child(layer)

	var panel := PanelContainer.new()
	panel.position = Vector2(14, 14)
	var viewport_size := get_viewport().get_visible_rect().size
	panel.custom_minimum_size = Vector2(minf(420.0, viewport_size.x - 28.0), 116.0)
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

	stamina_label = Label.new()
	stamina_label.add_theme_font_size_override("font_size", 15)
	stamina_label.add_theme_color_override("font_color", Color("#8fd2a0"))
	column.add_child(stamina_label)

	ammo_label = Label.new()
	ammo_label.add_theme_font_size_override("font_size", 15)
	ammo_label.add_theme_color_override("font_color", Color("#e6c36a"))
	column.add_child(ammo_label)

	hunter_health_label = Label.new()
	hunter_health_label.add_theme_font_size_override("font_size", 15)
	hunter_health_label.add_theme_color_override("font_color", Color("#e58b7b"))
	column.add_child(hunter_health_label)

	var ability_row := HBoxContainer.new()
	ability_row.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	ability_row.position = Vector2(-330, 136)
	ability_row.add_theme_constant_override("separation", 8)
	layer.add_child(ability_row)
	for ability in [
		{"id": "decoy", "label": "Q  ОБМАН"},
		{"id": "freeze", "label": "F  ЗАМОРОЗКА"},
		{"id": "bag", "label": "G  МЕШОК"}
	]:
		var ability_button := Button.new()
		ability_button.text = str(ability.label)
		ability_button.custom_minimum_size = Vector2(104, 48)
		ability_button.add_theme_font_size_override("font_size", 13)
		ability_button.pressed.connect(_use_ability.bind(str(ability.id)))
		ability_row.add_child(ability_button)
		ability_buttons.append(ability_button)
	ability_row.visible = OS.has_feature("mobile")

	var weapon_row := HBoxContainer.new()
	weapon_row.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	weapon_row.position = Vector2(-230, 192)
	weapon_row.add_theme_constant_override("separation", 8)
	layer.add_child(weapon_row)
	for action in [
		{"label": "СТРЕЛЯТЬ", "callback": Callable(self, "_fire_weapon")},
		{"label": "ПЕРЕЗАРЯДИТЬ", "callback": Callable(self, "_reload_weapon")}
	]:
		var weapon_button := Button.new()
		weapon_button.text = str(action.label)
		weapon_button.custom_minimum_size = Vector2(108, 48)
		weapon_button.add_theme_font_size_override("font_size", 13)
		weapon_button.pressed.connect(action.callback)
		weapon_row.add_child(weapon_button)
		weapon_buttons.append(weapon_button)
	weapon_row.visible = OS.has_feature("mobile")

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
			{"text": "КАК ИГРАТЬ", "action": Callable(self, "_show_controls_help")},
			{"text": "АРСЕНАЛ", "action": Callable(self, "_show_armory")},
			{"text": "ПРОФИЛЬ", "action": Callable(self, "_show_profile")},
			{"text": "НАСТРОЙКИ", "action": Callable(self, "_show_settings")},
			{"text": "ВЫХОД", "action": Callable(self, "_exit_game")}
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
	var viewport_size := get_viewport().get_visible_rect().size
	var panel_size := Vector2(minf(520.0, viewport_size.x - 28.0), minf(620.0, viewport_size.y - 28.0))
	panel.position = -panel_size * 0.5
	panel.custom_minimum_size = panel_size
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
	column.add_theme_constant_override("separation", 10)
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
		button.custom_minimum_size = Vector2(0, 48)
		button.add_theme_font_size_override("font_size", 17)
		button.pressed.connect(item["action"])
		column.add_child(button)

func _load_profile_stats() -> void:
	var config := ConfigFile.new()
	if config.load("user://otkat_hide_seek_profile.cfg") == OK:
		total_wins = int(config.get_value("stats", "wins", 0))
		total_losses = int(config.get_value("stats", "losses", 0))
		selected_weapon_id = str(config.get_value("loadout", "weapon", "ap_scout"))
	if not inventory.owns_weapon(selected_weapon_id):
		selected_weapon_id = "ap_scout"

func _save_profile_stats() -> void:
	var config := ConfigFile.new()
	config.set_value("stats", "wins", total_wins)
	config.set_value("stats", "losses", total_losses)
	config.set_value("loadout", "weapon", selected_weapon_id)
	config.save("user://otkat_hide_seek_profile.cfg")

func _show_profile() -> void:
	_show_screen(
		"ПРОФИЛЬ ВЫЖИВШЕГО",
		"Победы: %d\nПоражения: %d\nКредиты: %d\nОружие открыто: %d\nСкины открыты: %d\n\nВыбранное оружие: %s" % [
			total_wins, total_losses, inventory.credits, inventory.owned_weapons.size(),
			inventory.owned_skins.size(), selected_weapon_id
		],
		[{"text": "НАЗАД", "action": Callable(self, "_build_main_menu")}]
	)

func _show_armory() -> void:
	var buttons: Array = []
	for item in ArsenalRegistry.get_world_weapons("apocalypse"):
		var weapon_id := str(item.id)
		var button_text := ""
		var action: Callable
		if inventory.owns_weapon(weapon_id):
			button_text = "ВЫБРАТЬ: %s" % str(item.name)
			action = Callable(self, "_equip_weapon").bind(weapon_id)
		else:
			button_text = "КУПИТЬ: %s — %d кр." % [str(item.name), int(item.value)]
			action = Callable(self, "_buy_weapon").bind(weapon_id)
		buttons.append({"text": button_text, "action": action})
	buttons.append({"text": "НАЗАД", "action": Callable(self, "_build_main_menu")})
	_show_screen("АРСЕНАЛ", "Оружие мира Апокалипсиса. Покупки совершаются только за игровые кредиты. Выбранное оружие: %s." % selected_weapon_id, buttons)

func _buy_weapon(weapon_id: String) -> void:
	var item := ArsenalRegistry.get_weapon("apocalypse", weapon_id)
	if item.is_empty():
		return
	if not inventory.spend_credits(int(item.value)):
		_show_screen("НЕ ХВАТАЕТ КРЕДИТОВ", "Нужно %d кредитов. Сейчас у тебя %d." % [int(item.value), inventory.credits], [{"text": "В АРСЕНАЛ", "action": Callable(self, "_show_armory")}])
		return
	inventory.unlock_weapon(weapon_id)
	_equip_weapon(weapon_id)

func _equip_weapon(weapon_id: String) -> void:
	if not inventory.owns_weapon(weapon_id):
		return
	selected_weapon_id = weapon_id
	_save_profile_stats()
	weapon_runtime.equip("apocalypse", selected_weapon_id, inventory.get_equipped_skin(selected_weapon_id))
	_show_weapon_skins(weapon_id)

func _show_weapon_skins(weapon_id: String) -> void:
	var item := ArsenalRegistry.get_weapon("apocalypse", weapon_id)
	var buttons: Array = []
	for skin in item.get("skins", []):
		var skin_id := str(skin.id)
		var action: Callable
		var label_text: String
		if inventory.owns_skin(skin_id):
			label_text = "ЭКИПИРОВАТЬ СКИН: %s" % str(skin.name)
			action = Callable(self, "_equip_skin").bind(weapon_id, skin_id)
		else:
			label_text = "КУПИТЬ СКИН: %s — %d кр." % [str(skin.name), int(skin.value)]
			action = Callable(self, "_buy_skin").bind(weapon_id, skin_id)
		buttons.append({"text": label_text, "action": action})
	buttons.append({"text": "НАЗАД К ОРУЖИЮ", "action": Callable(self, "_show_armory")})
	_show_screen(str(item.name), "Выбирай оформление оружия. Скины не дают боевого преимущества.", buttons)

func _buy_skin(weapon_id: String, skin_id: String) -> void:
	var skin := ArsenalRegistry.get_skin("apocalypse", weapon_id, skin_id)
	if skin.is_empty():
		return
	if not inventory.spend_credits(int(skin.value)):
		_show_screen("НЕ ХВАТАЕТ КРЕДИТОВ", "Нужно %d кредитов. Сейчас у тебя %d." % [int(skin.value), inventory.credits], [{"text": "К СКИНАМ", "action": Callable(self, "_show_weapon_skins").bind(weapon_id)}])
		return
	inventory.unlock_skin(skin_id)
	_equip_skin(weapon_id, skin_id)

func _equip_skin(weapon_id: String, skin_id: String) -> void:
	if inventory.equip_skin(weapon_id, skin_id) and selected_weapon_id == weapon_id:
		weapon_runtime.equip("apocalypse", weapon_id, skin_id)
	_show_weapon_skins(weapon_id)

func _show_settings() -> void:
	_show_screen(
		"НАСТРОЙКИ",
		"Настрой управление и обзор под себя. Значения применяются сразу.",
		[
			{"text": "ЧУВСТВИТЕЛЬНОСТЬ: %.1f" % (player.mouse_sensitivity * 1000.0), "action": Callable(self, "_cycle_sensitivity")},
			{"text": "ПОЛЕ ЗРЕНИЯ: %d°" % int(player.camera.fov), "action": Callable(self, "_cycle_fov")},
			{"text": "НАЗАД", "action": Callable(self, "_build_main_menu")}
		]
	)

func _cycle_sensitivity() -> void:
	sensitivity_index = (sensitivity_index + 1) % SENSITIVITY_STEPS.size()
	player.mouse_sensitivity = SENSITIVITY_STEPS[sensitivity_index]
	player.touch_look_sensitivity = player.mouse_sensitivity * 1.65
	_show_settings()

func _cycle_fov() -> void:
	fov_index = (fov_index + 1) % FOV_STEPS.size()
	player.camera.fov = FOV_STEPS[fov_index]
	_show_settings()

func _exit_game() -> void:
	get_tree().quit()

func _show_controls_help() -> void:
	_show_screen(
		"УПРАВЛЕНИЕ",
		"КОМПЬЮТЕР\nWASD или стрелки — движение. Shift — бег (расходует выносливость). Ctrl — присесть и двигаться тише. V — переключить вид от первого/третьего лица. Мышь — обзор. E — маскировка. Q — обман, F — заморозка, G — мешок. Esc — пауза. R — новый раунд после завершения.\n\nANDROID\nЛевая половина экрана — движение. Правая — обзор. Кнопки «Бег», «Присесть», «Маскировка», «Камера» и три способности находятся на экране.\n\nЦЕЛЬ\nНайди предмет для маскировки до конца подготовки. Охотник может заметить тебя, если подойдёт близко. Переживи 150 секунд.",
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
	player.set_disguised(false)
	player.global_position = Vector3(-23.0, 0.1, 17.0)
	player.stamina = 100.0
	player.noise_timer = 0.0
	player.touch_sprint = false
	player.touch_crouch = false
	player.is_sprinting = false
	player.is_crouching = false
	player._set_crouch_pose(false)
	abilities.cooldowns.clear()
	abilities.set_process(true)
	weapon_runtime.set_process(true)
	weapon_runtime.equip("apocalypse", selected_weapon_id, inventory.get_equipped_skin(selected_weapon_id))
	pending_fire = false
	victory_message = "Ты пережил всю охоту и выбрался из торгового центра."
	player.set_physics_process(true)
	player.set_process_input(true)
	var touch_controls := player.get_node_or_null("TouchControls")
	if touch_controls:
		touch_controls.visible = OS.has_feature("mobile")
	for button in ability_buttons:
		button.get_parent().visible = OS.has_feature("mobile")
	for button in weapon_buttons:
		button.get_parent().visible = OS.has_feature("mobile")
	hunter.health = 100
	hunter.global_position = Vector3(23.0, 0.1, -17.0)
	hunter.frozen_time = 0.0
	hunter.bagged_time = 0.0
	hunter.lure_time = 0.0
	hunter.state = "patrol"
	hunter.patrol_index = 0
	hunter.set_physics_process(false)
	hud_hint.text = "WASD — движение  •  E — маскировка  •  Esc — пауза"
	hud_status.text = "Найди предмет и замаскируйся до выхода охотника."
	_update_hud()
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(_delta: float) -> void:
	if pending_fire:
		pending_fire = false
		if round_active and not finished and round_phase == "hunt":
			weapon_runtime.try_fire(player.camera.global_position, player.get_camera_direction())

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

func _use_ability(ability_id: String) -> void:
	if not round_active or finished or round_phase != "hunt":
		hud_status.text = "Способности доступны только во время охоты."
		return
	var ability_position := player.global_position - player.global_transform.basis.z * 4.0
	if player.disguised:
		ability_position += Vector3.UP * 0.5
	abilities.global_position = ability_position
	abilities.use_ability(ability_id, hunter)

func _fire_weapon() -> void:
	if not round_active or finished or round_phase != "hunt":
		hud_status.text = "Стрелять можно только во время охоты."
		return
	if player.disguised:
		hud_status.text = "Нельзя стрелять, пока ты замаскирован."
		return
	pending_fire = true

func _reload_weapon() -> void:
	if not round_active or finished:
		return
	weapon_runtime.reload_weapon()

func _on_ammo_changed(current: int, reserve: int) -> void:
	if is_instance_valid(ammo_label):
		ammo_label.text = "ПАТРОНЫ  %02d / %02d" % [current, reserve]

func _on_weapon_blocked(reason: String) -> void:
	hud_status.text = reason

func _on_weapon_hit(target: Object, weapon_id: String) -> void:
	if target == hunter:
		var weapon_data := ArsenalRegistry.get_weapon("apocalypse", weapon_id)
		var damage := int(weapon_data.get("damage", 0))
		hunter.take_damage(damage)
		hud_status.text = "Попадание! Здоровье охотника: %d%%" % hunter.health

func _on_hunter_defeated() -> void:
	victory_message = "Ты победил охотника и открыл выход из торгового центра!"
	_finish(true)

func _on_player_noise(point: Vector3, radius: float) -> void:
	if round_phase == "hunt" and not player.disguised:
		hunter.hear_noise(point, radius)

func _on_decoy_created(point: Vector3, duration: float) -> void:
	hunter.investigate_position(point, duration)
	var decoy: Node3D
	if player.disguised and is_instance_valid(disguise_visual):
		decoy = disguise_visual.duplicate() as Node3D
		decoy.global_position = point
	else:
		decoy = player.body_visual.duplicate() as Node3D
		decoy.global_position = point + Vector3.UP * 0.9
	decoy.name = "DecoyEcho"
	add_child(decoy)
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(decoy):
		decoy.queue_free()

func _on_hunter_frozen(duration: float) -> void:
	hunter.apply_freeze(duration)
	hud_status.text = "Охотник заморожен на %.1f сек." % duration

func _on_hunter_bagged(duration: float) -> void:
	hunter.apply_bag(duration)
	hud_status.text = "Охотник замедлен на %.1f сек." % duration

func _on_ability_used(ability_id: String, cooldown: float) -> void:
	var names := {"decoy": "Обман", "freeze": "Заморозка", "bag": "Мешок"}
	hud_status.text = "%s активирована. Перезарядка: %d сек." % [names.get(ability_id, ability_id), int(cooldown)]

func _on_ability_blocked(reason: String) -> void:
	hud_status.text = reason

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
			_make_prop_part(disguise_visual, "SuitcaseBody", Vector3(0.85, 0.55, 0.48), Vector3(0, -0.22, 0), Color("#806448"))
			_make_prop_part(disguise_visual, "SuitcaseHandle", Vector3(0.32, 0.12, 0.08), Vector3(0, 0.12, 0), Color("#343638"))

func _on_player_caught() -> void:
	_finish(false)

func _finish(won: bool) -> void:
	if finished:
		return
	if won:
		total_wins += 1
		inventory.add_credits(100)
		victory_message += "\nНаграда: +100 кредитов."
	else:
		total_losses += 1
		inventory.add_credits(25)
	_save_profile_stats()
	finished = true
	round_active = false
	player.set_physics_process(false)
	player.set_process_input(false)
	hunter.set_physics_process(false)
	abilities.set_process(false)
	weapon_runtime.set_process(false)
	pending_fire = false
	var touch_controls := player.get_node_or_null("TouchControls")
	if touch_controls:
		touch_controls.visible = false
	for button in ability_buttons:
		button.get_parent().visible = false
	for button in weapon_buttons:
		button.get_parent().visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var result_title := "ПОБЕДА!" if won else "ТЕБЯ НАШЛИ"
	var result_body := victory_message if won else "Охотник обнаружил тебя. Попробуй другую точку, используй маскировку и способности."
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
	abilities.set_process(false)
	weapon_runtime.set_process(false)
	pending_fire = false
	var touch_controls := player.get_node_or_null("TouchControls")
	if touch_controls:
		touch_controls.visible = false
	for button in ability_buttons:
		button.get_parent().visible = false
	for button in weapon_buttons:
		button.get_parent().visible = false
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
	abilities.set_process(true)
	weapon_runtime.set_process(true)
	player.set_physics_process(true)
	player.set_process_input(true)
	hunter.set_physics_process(round_phase == "hunt")
	var touch_controls := player.get_node_or_null("TouchControls")
	if touch_controls:
		touch_controls.visible = OS.has_feature("mobile")
	for button in ability_buttons:
		button.get_parent().visible = OS.has_feature("mobile")
	for button in weapon_buttons:
		button.get_parent().visible = OS.has_feature("mobile")
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
		elif event.keycode == KEY_R and round_active:
			_reload_weapon()
		elif event.keycode == KEY_Q:
			_use_ability("decoy")
		elif event.keycode == KEY_F:
			_use_ability("freeze")
		elif event.keycode == KEY_G:
			_use_ability("bag")

func _update_hud() -> void:
	if not is_instance_valid(hud_timer) or not round_active:
		return
	var prefix := "ПОДГОТОВКА" if round_phase == "prepare" else "ОХОТА"
	hud_timer.text = "%s  •  %03d" % [prefix, int(ceil(maxf(phase_time, 0.0)))]
	if is_instance_valid(stamina_label):
		stamina_label.text = "ВЫНОСЛИВОСТЬ  %d%%" % int(round(player.stamina))
	if is_instance_valid(hunter_health_label):
		hunter_health_label.text = "ОХОТНИК  %d%%" % hunter.health
