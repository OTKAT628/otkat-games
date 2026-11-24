extends Node2D

const PLAYER_SPEED := 250.0
const SEEKER_SPEED := 105.0
const ROUND_LENGTH := 60.0
const HIDE_LENGTH := 10.0
const ARENA := Rect2(55, 95, 1170, 565)

var player_position := Vector2(150, 570)
var seeker_position := Vector2(1100, 150)
var hidden := false
var phase := "hide"
var phase_left := HIDE_LENGTH
var round_left := ROUND_LENGTH
var finished := false
var won := false

var timer_label: Label
var message_label: Label
var restart_button: Button

var hide_spots: Array[Rect2] = [
	Rect2(260, 210, 115, 78),
	Rect2(575, 475, 125, 78),
	Rect2(925, 250, 115, 78)
]

func _ready() -> void:
	_build_hud()
	_update_hud()
	queue_redraw()

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	timer_label = Label.new()
	timer_label.position = Vector2(28, 18)
	timer_label.add_theme_font_size_override("font_size", 25)
	timer_label.add_theme_color_override("font_color", Color("#f5f7fb"))
	layer.add_child(timer_label)

	message_label = Label.new()
	message_label.position = Vector2(30, 57)
	message_label.add_theme_font_size_override("font_size", 16)
	message_label.add_theme_color_override("font_color", Color("#b8c8d9"))
	layer.add_child(message_label)

	var help := Label.new()
	help.position = Vector2(28, 675)
	help.text = "WASD / стрелки — движение     E — спрятаться / выйти     R — начать заново"
	help.add_theme_font_size_override("font_size", 15)
	help.add_theme_color_override("font_color", Color("#e4edf7"))
	layer.add_child(help)

	restart_button = Button.new()
	restart_button.text = "Играть снова"
	restart_button.position = Vector2(1080, 20)
	restart_button.visible = false
	restart_button.pressed.connect(_restart)
	layer.add_child(restart_button)

	message_label.text = "У тебя 10 секунд, чтобы занять укрытие."

func _process(delta: float) -> void:
	if finished:
		return

	if phase == "hide":
		phase_left -= delta
		if phase_left <= 0.0:
			phase = "seek"
			message_label.text = "Охотник начал поиск! Продержись 60 секунд."
	else:
		round_left -= delta
		if not hidden:
			var direction := (player_position - seeker_position).normalized()
			seeker_position += direction * SEEKER_SPEED * delta
			if seeker_position.distance_to(player_position) < 27.0:
				_finish(false)
		if round_left <= 0.0 and not finished:
			_finish(true)

	_update_hud()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if finished or hidden:
		return
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0
	if direction.length() > 1.0:
		direction = direction.normalized()
	player_position += direction * PLAYER_SPEED * delta
	player_position.x = clampf(player_position.x, ARENA.position.x + 20.0, ARENA.end.x - 20.0)
	player_position.y = clampf(player_position.y, ARENA.position.y + 20.0, ARENA.end.y - 20.0)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			_toggle_hide()
		elif event.keycode == KEY_R:
			_restart()

func _toggle_hide() -> void:
	if finished:
		return
	if hidden:
		hidden = false
		message_label.text = "Ты покинул укрытие. Будь осторожен!"
		return
	for spot in hide_spots:
		if spot.grow(38.0).has_point(player_position):
			hidden = true
			message_label.text = "Ты спрятался. Охотник тебя не видит."
			return
	message_label.text = "Подойди ближе к отмеченному укрытию и нажми E."

func _finish(player_won: bool) -> void:
	finished = true
	won = player_won
	message_label.text = "ПОБЕДА! Ты продержался!" if won else "ТЕБЯ НАШЛИ! Попробуй ещё раз."
	restart_button.visible = true

func _restart() -> void:
	player_position = Vector2(150, 570)
	seeker_position = Vector2(1100, 150)
	hidden = false
	phase = "hide"
	phase_left = HIDE_LENGTH
	round_left = ROUND_LENGTH
	finished = false
	restart_button.visible = false
	message_label.text = "У тебя 10 секунд, чтобы занять укрытие."
	_update_hud()
	queue_redraw()

func _update_hud() -> void:
	if phase == "hide":
		timer_label.text = "OTKAT HIDE & SEEK   |   ПРЯЧЬСЯ: %02d" % int(ceil(maxf(phase_left, 0.0)))
	else:
		timer_label.text = "OTKAT HIDE & SEEK   |   ОСТАЛОСЬ: %02d" % int(ceil(maxf(round_left, 0.0)))

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color("#0b1422"))
	draw_rect(ARENA, Color("#1b3042"))
	for x in range(75, 1220, 48):
		draw_line(Vector2(x, 98), Vector2(x, 658), Color(0.45, 0.62, 0.72, 0.12), 1.0)
	for y in range(115, 660, 48):
		draw_line(Vector2(58, y), Vector2(1222, y), Color(0.45, 0.62, 0.72, 0.12), 1.0)
	for spot in hide_spots:
		draw_rect(spot, Color("#d99a4e"))
		draw_rect(spot, Color("#ffe0a8"), false, 3.0)
		draw_string(ThemeDB.fallback_font, spot.position + Vector2(14, 45), "УКРЫТИЕ", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#34230e"))
	draw_circle(seeker_position, 19.0, Color("#ff627c"))
	draw_circle(seeker_position + Vector2(-6, -4), 3.0, Color("#39121c"))
	draw_circle(seeker_position + Vector2(6, -4), 3.0, Color("#39121c"))
	if not hidden:
		draw_circle(player_position, 16.0, Color("#65e5df"))
		draw_circle(player_position + Vector2(-5, -4), 3.0, Color("#102b3d"))
		draw_circle(player_position + Vector2(5, -4), 3.0, Color("#102b3d"))
	if finished:
		draw_rect(Rect2(290, 285, 700, 120), Color(0.02, 0.05, 0.09, 0.9))
		draw_string(ThemeDB.fallback_font, Vector2(420, 355), "ПОБЕДА!" if won else "ТЕБЯ НАШЛИ!", HORIZONTAL_ALIGNMENT_LEFT, 450, 36, Color.WHITE)
