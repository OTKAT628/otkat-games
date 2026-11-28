extends Control

const PLACES := [
    {"city":"Хельсинки","country":"Финляндия","clue":"Трамваи, северная архитектура и финские слова на вывесках","region":"Европа"},
    {"city":"Токио","country":"Япония","clue":"Плотная городская застройка, японская письменность и автоматы с напитками","region":"Азия"},
    {"city":"Каир","country":"Египет","clue":"Арабские вывески, сухой климат и пальмы вдоль улиц","region":"Африка"},
    {"city":"Буэнос-Айрес","country":"Аргентина","clue":"Испанские вывески, широкие проспекты и платаны","region":"Южная Америка"},
    {"city":"Рейкьявик","country":"Исландия","clue":"Скандинавские надписи, вулканические пейзажи и яркие крыши","region":"Европа"},
    {"city":"Ванкувер","country":"Канада","clue":"Английские и французские надписи, горы у океана и хвойные леса","region":"Северная Америка"},
    {"city":"Марракеш","country":"Марокко","clue":"Арабские и французские вывески, медина и охристые стены","region":"Африка"},
    {"city":"Сеул","country":"Южная Корея","clue":"Корейский хангыль, горные силуэты и современные высотки","region":"Азия"}
]

var rng := RandomNumberGenerator.new()
var round_label: Label
var clue_label: Label
var feedback_label: Label
var score_label: Label
var answers_box: VBoxContainer
var next_button: Button
var current_place: Dictionary
var round_number := 0
var points := 0
var answered := false
var finished := false

func _ready() -> void:
    rng.randomize()
    _build_ui()
    _start_round()

func _build_ui() -> void:
    var background := ColorRect.new()
    background.color = Color("#101827")
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)

    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)

    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(560, 0)
    center.add_child(panel)

    var layout := VBoxContainer.new()
    layout.add_theme_constant_override("separation", 14)
    panel.add_child(layout)

    var title := Label.new()
    title.text = "OTKAT · WORLD DETECTIVE"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 28)
    layout.add_child(title)

    round_label = Label.new()
    round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(round_label)

    var intro := Label.new()
    intro.text = "Определи город по подсказкам. За верный ответ — 100 очков."
    intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    layout.add_child(intro)

    clue_label = Label.new()
    clue_label.custom_minimum_size = Vector2(500, 120)
    clue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    clue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    clue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    clue_label.add_theme_font_size_override("font_size", 20)
    layout.add_child(clue_label)

    answers_box = VBoxContainer.new()
    answers_box.add_theme_constant_override("separation", 8)
    layout.add_child(answers_box)

    feedback_label = Label.new()
    feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    layout.add_child(feedback_label)

    score_label = Label.new()
    score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(score_label)

    next_button = Button.new()
    next_button.text = "Следующая локация"
    next_button.custom_minimum_size = Vector2(0, 48)
    next_button.disabled = true
    next_button.pressed.connect(_advance)
    layout.add_child(next_button)

    var credit := Label.new()
    credit.text = "Created by OTKAT Games · Android edition"
    credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    credit.add_theme_font_size_override("font_size", 11)
    layout.add_child(credit)

func _start_round() -> void:
    if round_number >= 5:
        finished = true
        round_label.text = "Экспедиция завершена"
        clue_label.text = "Итоговый результат: %d из 500 очков." % points
        answers_box.visible = false
        feedback_label.text = "Ты прошёл первый маршрут World Detective."
        next_button.text = "Начать заново"
        next_button.disabled = false
        return

    finished = false
    round_number += 1
    answered = false
    current_place = PLACES[rng.randi_range(0, PLACES.size() - 1)]
    round_label.text = "Маршрут · раунд %d/5" % round_number
    clue_label.text = "%s\n\nРегион: %s. Какой это город?" % [current_place.clue, current_place.region]
    feedback_label.text = ""
    score_label.text = "Очки: %d" % points
    next_button.text = "Следующая локация"
    next_button.disabled = true
    answers_box.visible = true
    for child in answers_box.get_children():
        child.queue_free()

    var choices: Array[Dictionary] = [current_place]
    while choices.size() < 4:
        var candidate: Dictionary = PLACES[rng.randi_range(0, PLACES.size() - 1)]
        if not choices.any(func(place): return place.city == candidate.city):
            choices.append(candidate)
    choices.shuffle()

    for place in choices:
        var answer := place
        var button := Button.new()
        button.text = answer.city
        button.custom_minimum_size = Vector2(0, 46)
        button.pressed.connect(func(): _choose(answer))
        answers_box.add_child(button)

func _choose(choice: Dictionary) -> void:
    if answered:
        return
    answered = true
    for child in answers_box.get_children():
        if child is Button:
            child.disabled = true
    if choice.city == current_place.city:
        points += 100
        feedback_label.text = "Верно! %s, %s. +100" % [current_place.city, current_place.country]
    else:
        feedback_label.text = "Пока нет. Это %s, %s." % [current_place.city, current_place.country]
    score_label.text = "Очки: %d" % points
    next_button.disabled = false

func _advance() -> void:
    if finished:
        round_number = 0
        points = 0
    _start_round()
