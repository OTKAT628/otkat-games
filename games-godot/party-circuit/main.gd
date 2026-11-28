extends Control

const BG = Color("#101525")
var scores: Array[int] = [0, 0, 0, 0]
var player_count := 2
var round_no := 1
var prompt_label: Label
var score_label: Label
var status_label: Label
var buttons: Array[Button] = []
var round_open := true
var tasks := [
	{"title":"РЕАКЦИЯ","prompt":"Кто первым нажмёт свою кнопку — получает очко."},
	{"title":"СЧЁТ НА СКОРОСТЬ","prompt":"Реши пример на экране и нажми свою кнопку первым."},
	{"title":"ПАМЯТЬ","prompt":"Запомни последовательность цветов и будь готов ответить."},
	{"title":"ВНИМАТЕЛЬНОСТЬ","prompt":"Найди нужный символ среди отвлекающих знаков."}
]
var current_task := 0

func _ready() -> void:
	randomize()
	_build_ui()
	_new_round()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 18)
	root.add_theme_constant_override("margin_left", 36)
	root.add_theme_constant_override("margin_top", 28)
	root.add_theme_constant_override("margin_right", 36)
	root.add_theme_constant_override("margin_bottom", 28)
	add_child(root)
	var title := Label.new()
	title.text = "OTKAT PARTY CIRCUIT"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("#9fe8cf"))
	root.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Локальная вечеринка · 2–4 игрока · раунды и общий счёт"
	root.add_child(subtitle)
	var settings := HBoxContainer.new()
	root.add_child(settings)
	var count_label := Label.new()
	count_label.text = "Игроков:"
	settings.add_child(count_label)
	var count := OptionButton.new()
	for n in range(2, 5):
		count.add_item(str(n), n)
	count.select(0)
	count.item_selected.connect(func(index: int):
		player_count = index + 2
		_new_round()
	)
	settings.add_child(count)
	prompt_label = Label.new()
	prompt_label.custom_minimum_size.y = 150
	prompt_label.add_theme_font_size_override("font_size", 25)
	prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(prompt_label)
	status_label = Label.new()
	status_label.text = "Нажмите кнопку своего игрока."
	root.add_child(status_label)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(grid)
	for i in range(4):
		var b := Button.new()
		b.custom_minimum_size = Vector2(260, 100)
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(_claim.bind(i))
		grid.add_child(b)
		buttons.append(b)
	score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", 18)
	root.add_child(score_label)
	var next := Button.new()
	next.text = "Следующий раунд"
	next.custom_minimum_size.y = 48
	next.pressed.connect(_new_round)
	root.add_child(next)

func _new_round() -> void:
	round_open = true
	current_task = (round_no - 1) % tasks.size()
	var task: Dictionary = tasks[current_task]
	var challenge := ""
	if current_task == 1:
		var a := randi_range(3, 18)
		var b := randi_range(2, 12)
		challenge = "\n\nСколько будет %d × %d?" % [a, b]
		prompt_label.set_meta("answer", a * b)
	elif current_task == 2:
		var sequence := ["🟦","🟨","🟥","🟩","🟦"]
		challenge = "\n\n" + "  ".join(sequence) + "\nСкажи последовательность вслух и нажми кнопку."
		prompt_label.set_meta("answer", -1)
	elif current_task == 3:
		challenge = "\n\nНайди глазами три одинаковых знака: ▲ ◆ ▲ ● ▲"
		prompt_label.set_meta("answer", -1)
	else:
		prompt_label.set_meta("answer", -1)
	prompt_label.text = "%s\n%s%s" % [task.title, task.prompt, challenge]
	status_label.text = "Раунд %d · Первый нажавший получает очко" % round_no
	for i in range(4):
		buttons[i].visible = i < player_count
		buttons[i].disabled = false
		buttons[i].text = "ИГРОК %d\nНАЖАТЬ" % (i + 1)
	_update_scores()

func _claim(index: int) -> void:
	if not round_open or index >= player_count:
		return
	round_open = false
	scores[index] += 1
	status_label.text = "Раунд забрал игрок %d!" % (index + 1)
	for b in buttons:
		b.disabled = true
	round_no += 1
	_update_scores()

func _update_scores() -> void:
	var parts: Array[String] = []
	for i in range(player_count):
		parts.append("Игрок %d: %d" % [i + 1, scores[i]])
	score_label.text = "     ".join(parts)
