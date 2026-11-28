extends Control

const LOBBY_SCENE = "res://scenes/lobby_3d.tscn"
const SKINS = ["Путник","Неон","Лесной","Тень","Золотой","Астро"]
const SKIN_COLORS = [Color("#59c7d9"),Color("#e85cbd"),Color("#6aab68"),Color("#54515e"),Color("#e6b84f"),Color("#8d91e8")]
var skin_index := 0
var room_name := "Комната друзей"
var room_password := ""
var is_public := false
var round_seconds := 180
var rerolls := 2
var page: VBoxContainer

func _ready() -> void:
 page = $Center/Panel as VBoxContainer
 _show_main()

func _clear(title: String, subtitle := "") -> void:
 for child in page.get_children(): child.queue_free()
 var heading := Label.new()
 heading.text = title
 heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 heading.add_theme_font_size_override("font_size", 30)
 page.add_child(heading)
 if subtitle != "":
  var note := Label.new()
  note.text = subtitle
  note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  page.add_child(note)

func _button(caption: String, callback: Callable) -> void:
 var b := Button.new()
 b.text = caption
 b.custom_minimum_size = Vector2(500, 44)
 b.pressed.connect(callback)
 page.add_child(b)

func _line(caption: String, value: String, secret := false) -> LineEdit:
 var l := Label.new()
 l.text = caption
 page.add_child(l)
 var f := LineEdit.new()
 f.text = value
 f.secret = secret
 f.custom_minimum_size = Vector2(500, 38)
 page.add_child(f)
 return f

func _select(caption: String, values: Array, current: String) -> OptionButton:
 var l := Label.new()
 l.text = caption
 page.add_child(l)
 var o := OptionButton.new()
 for value in values: o.add_item(str(value))
 var idx := values.find(current)
 if idx >= 0: o.select(idx)
 o.custom_minimum_size = Vector2(500, 38)
 page.add_child(o)
 return o

func _show_main() -> void:
 _clear("OTKAT HIDE & SEEK","Главное меню · 2D")
 _button("Одиночная игра", _solo)
 _button("Многопользовательская игра", _multiplayer)
 _button("Персонаж и скины", _skins)
 _button("Карты и предметы", _maps)
 _button("Настройки", _settings)
 _button("Выход", func(): get_tree().quit())

func _multiplayer() -> void:
 _clear("МУЛЬТИПЛЕЕР","Создать комнату или присоединиться к друзьям")
 _button("Создать мир", _create_room)
 _button("Подключиться по коду", _join_room)
 _button("Быстрая игра", _quick_match)
 _button("Назад", _show_main)

func _create_room() -> void:
 _clear("СОЗДАТЬ МИР","После создания откроется отдельное 3D-лобби ожидания")
 var room := _line("Название комнаты", room_name)
 var password := _line("Пароль закрытой комнаты", room_password, true)
 var access := _select("Доступ", ["Закрытая · по паролю","Открытая"], "Открытая" if is_public else "Закрытая · по паролю")
 var duration := _select("Длительность раунда", ["90","120","180","240","300"], str(round_seconds))
 var rolls := _select("Перевыборы предмета", ["0","1","2","3","4","5"], str(rerolls))
 _button("Создать и перейти в 3D-лобби", func():
  room_name = room.text.strip_edges()
  room_password = password.text
  is_public = access.selected == 1
  round_seconds = int(duration.get_item_text(duration.selected))
  rerolls = int(rolls.get_item_text(rolls.selected))
  if room_name.is_empty() or (not is_public and room_password.is_empty()):
   _notice("Укажи название и пароль для закрытой комнаты.")
   return
  _open_lobby(false)
 )
 _button("Назад", _multiplayer)

func _join_room() -> void:
 _clear("ПОДКЛЮЧЕНИЕ","Вход по приглашению")
 _line("Имя игрока","Игрок")
 _line("Название комнаты","")
 _line("Код комнаты (IP:порт)","")
 _line("Пароль","",true)
 _notice("Подключение к серверу и проверка пароля будут связаны с сетевым модулем.")
 _button("Назад", _multiplayer)

func _quick_match() -> void:
 _clear("БЫСТРАЯ ИГРА","Поиск открытых комнат")
 _notice("Каталог публичных серверов ещё не развёрнут. Можно создать открытую комнату и пригласить друзей.")
 _button("Создать открытую комнату", func():
  is_public = true
  room_name = "Открытая комната"
  room_password = ""
  _create_room()
 )
 _button("Назад", _multiplayer)

func _skins() -> void:
 _clear("ПЕРСОНАЖ И СКИНЫ","Выбери внешний вид. Выбор сохраняется при входе в 3D-лобби.")
 var preview := ColorRect.new()
 preview.custom_minimum_size = Vector2(500, 70)
 preview.color = SKIN_COLORS[skin_index]
 page.add_child(preview)
 var option := _select("Скин", SKINS, SKINS[skin_index])
 _button("Применить", func():
  skin_index = option.selected
  _skins()
 )
 _button("Назад", _show_main)

func _maps() -> void:
 _clear("КАРТЫ И ПРЕДМЕТЫ","Каталог будет расширяться отдельными пакетами карт")
 for map_name in ["Туманный лес · хоррор","Неоновый квартал · Hide Zone mood","Последний рейс · самолёт","Фабрика игрушек · мультяшная","Святилище луны · аниме","Город героев · комикс","Северное королевство · мифическое фэнтези"]:
  var l := Label.new()
  l.text = "• " + map_name
  page.add_child(l)
 _notice("Каждая карта получит собственный набор из 20–60 предметов. Дополнительные карты устанавливаются отдельно.")
 _button("Назад", _show_main)

func _settings() -> void:
 _clear("НАСТРОЙКИ","Параметры матча по умолчанию")
 var duration := _select("Длительность раунда", ["90","120","180","240","300"], str(round_seconds))
 var rolls := _select("Перевыборы", ["0","1","2","3","4","5"], str(rerolls))
 _button("Сохранить", func():
  round_seconds = int(duration.get_item_text(duration.selected))
  rerolls = int(rolls.get_item_text(rolls.selected))
  _show_main()
 )
 _button("Назад", _show_main)

func _solo() -> void:
 room_name = "Одиночная игра"
 is_public = false
 _open_lobby(true)

func _open_lobby(solo: bool) -> void:
 var lobby := load(LOBBY_SCENE) as PackedScene
 if lobby == null:
  _notice("Сцена 3D-лобби пока недоступна.")
  return
 var err := get_tree().change_scene_to_packed(lobby)
 if err != OK:
  _notice("Не удалось открыть 3D-лобби: %s" % err)
  return
 get_tree().set_meta("otkat_lobby_config", {
  "room_name": room_name,
  "password": room_password,
  "public": is_public,
  "duration": round_seconds,
  "rerolls": rerolls,
  "skin_index": skin_index,
  "solo": solo
 })

func _notice(message: String) -> void:
 var l := Label.new()
 l.text = message
 l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 l.add_theme_color_override("font_color", Color("#ffb8a8"))
 page.add_child(l)
