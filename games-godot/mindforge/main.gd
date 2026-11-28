extends Control

var level := 1
var points := 0
var expected := 0
var question: Label
var answer: LineEdit
var feedback: Label
var progress: Label
var hint_text := ""

func _ready() -> void:
	randomize()
	_build()
	_new_puzzle()

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#111827")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var panel := VBoxContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_constant_override("separation", 20)
	panel.offset_left = 56
	panel.offset_top = 42
	panel.offset_right = -56
	panel.offset_bottom = -42
	add_child(panel)
	var title := Label.new()
	title.text = "OTKAT MINDFORGE"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color("#a5c8ff"))
	panel.add_child(title)
	var intro := Label.new()
	intro.text = "Логическая кампания · числа · закономерности · память · шифры"
	panel.add_child(intro)
	progress = Label.new()
	progress.add_theme_font_size_override("font_size", 18)
	panel.add_child(progress)
	question = Label.new()
	question.custom_minimum_size.y = 190
	question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question.add_theme_font_size_override("font_size", 30)
	panel.add_child(question)
	answer = LineEdit.new()
	answer.placeholder_text = "Твой ответ"
	answer.custom_minimum_size.y = 58
	answer.add_theme_font_size_override("font_size", 22)
	answer.text_submitted.connect(func(_value: String): _check())
	panel.add_child(answer)
	var actions := HBoxContainer.new()
	panel.add_child(actions)
	var submit := Button.new()
	submit.text = "Проверить ответ"
	submit.custom_minimum_size = Vector2(220, 54)
	submit.pressed.connect(_check)
	actions.add_child(submit)
	var hint := Button.new()
	hint.text = "Подсказка"
	hint.custom_minimum_size = Vector2(150, 54)
	hint.pressed.connect(func(): feedback.text = hint_text)
	actions.add_child(hint)
	feedback = Label.new()
	feedback.add_theme_font_size_override("font_size", 20)
	panel.add_child(feedback)

func _new_puzzle() -> void:
	progress.text = "Уровень %d / 30     Очки: %d" % [level, points]
	answer.text = ""
	feedback.text = ""
	var a := randi_range(3, 14)
	var b := randi_range(2, 9)
	match (level - 1) % 6:
		0:
			expected = a * b
			question.text = "ЧИСЛОВАЯ МАШИНА\n\n%d × %d = ?" % [a, b]
			hint_text = "Умножь %d на %d." % [a, b]
		1:
			expected = a + b * 2
			question.text = "ДВОЙНОЙ ШАГ\n\n%d, %d, %d, ?" % [a, a + b, a + 2*b]
			hint_text = "Каждый раз прибавляется %d." % b
		2:
			expected = a * a
			question.text = "КВАДРАТЫ\n\n1, 4, 9, 16, 25, ?" 
			expected = 36
			hint_text = "Это квадраты натуральных чисел."
		3:
			expected = a - b
			question.text = "БАЛАНС\n\nНа складе %d кристаллов. Потратили %d. Сколько осталось?" % [a, b]
			hint_text = "Вычти потраченное из начального количества."
		4:
			expected = a + b
			question.text = "КОД ДОСТУПА\n\nПервая цифра %d, вторая %d. Введи их сумму." % [a, b]
			hint_text = "Сложи две цифры."
		5:
			expected = a * 2 + b
			question.text = "СИГНАЛ\n\nЕсли A=%d, B=%d, вычисли 2A+B." % [a, b]
			hint_text = "Сначала удвой A, затем прибавь B."
	feedback.text = "Реши задачу и введи целое число."

func _check() -> void:
	if answer.text.strip_edges().is_valid_int() == false:
		feedback.text = "Введи целое число."
		return
	if int(answer.text) == expected:
		points += 10
		level += 1
		if level > 30:
			question.text = "КАМПАНИЯ ПРОЙДЕНА!\n\nТы решил все 30 задач."
			feedback.text = "Итог: %d очков. Можно начать заново." % points
			var restart := Button.new()
			restart.text = "Новая кампания"
			restart.pressed.connect(func():
				level = 1
				points = 0
				restart.queue_free()
				_new_puzzle()
			)
			add_child(restart)
			return
		feedback.text = "Верно! +10 очков."
		_new_puzzle()
	else:
		feedback.text = "Пока неверно. Попробуй ещё раз."
