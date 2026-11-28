extends Node2D

const GAME_SCRIPT := preload("res://scripts/game.gd")
const DEFAULT_PORT := 27015
const MAX_PLAYERS := 8

var ui: Control
var page: VBoxContainer
var status_label: Label
var world_name := "Новый мир"
var world_password := ""
var is_public := false
var player_name := "Игрок"
var game_node: Node
var remote_positions: Dictionary = {}
var remote_names: Dictionary = {}
var sync_elapsed := 0.0
var authenticated := {}
var server_password := ""

func _ready() -> void:
    _build_shell()
    _show_main_menu()

func _build_shell() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    ui = Control.new()
    ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(ui)
    var bg := ColorRect.new()
    bg.color = Color("#0b1422")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.add_child(bg)
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.add_child(center)
    page = VBoxContainer.new()
    page.custom_minimum_size = Vector2(430, 0)
    page.add_theme_constant_override("separation", 14)
    center.add_child(page)

func _clear_page(title: String, subtitle: String = "") -> void:
    for child in page.get_children():
        child.queue_free()
    var heading := Label.new()
    heading.text = title
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    heading.add_theme_font_size_override("font_size", 34)
    heading.add_theme_color_override("font_color", Color("#f4f7fb"))
    page.add_child(heading)
    if not subtitle.is_empty():
        var sub := Label.new()
        sub.text = subtitle
        sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        sub.add_theme_color_override("font_color", Color("#aebed0"))
        page.add_child(sub)

func _add_button(caption: String, action: Callable, disabled := false) -> Button:
    var button := Button.new()
    button.text = caption
    button.custom_minimum_size = Vector2(390, 48)
    button.disabled = disabled
    button.pressed.connect(action)
    page.add_child(button)
    return button

func _add_field(caption: String, value: String, secret := false) -> LineEdit:
    var label := Label.new()
    label.text = caption
    label.add_theme_color_override("font_color", Color("#dce6f2"))
    page.add_child(label)
    var field := LineEdit.new()
    field.text = value
    field.custom_minimum_size = Vector2(390, 42)
    field.secret = secret
    page.add_child(field)
    return field

func _add_status(value: String) -> void:
    status_label = Label.new()
    status_label.text = value
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.add_theme_color_override("font_color", Color("#8fd8d1"))
    page.add_child(status_label)

func _show_main_menu() -> void:
    _clear_page("OTKAT HIDE & SEEK", "Прятки · одиночный режим и игра с друзьями")
    _add_button("Одиночная игра", _start_solo)
    _add_button("Многопользовательская игра", _show_multiplayer_menu)
    _add_button("Настройки", _show_settings)
    _add_button("Выход", func(): get_tree().quit())

func _show_multiplayer_menu() -> void:
    _clear_page("МУЛЬТИПЛЕЕР", "Создай комнату или присоединись к друзьям")
    _add_button("Создать мир", _show_create_world)
    _add_button("Подключиться по коду", _show_join_world)
    _add_button("Быстрая игра · открытые миры", _show_quick_match)
    _add_button("Назад", _show_main_menu)

func _show_create_world() -> void:
    _clear_page("СОЗДАТЬ МИР", "Задай имя комнаты и выбери доступ")
    var name_field := _add_field("Имя мира", world_name)
    var password_field := _add_field("Пароль (для закрытого мира)", world_password, true)
    var visibility := CheckButton.new()
    visibility.text = "Открытый мир — без пароля"
    visibility.button_pressed = is_public
    page.add_child(visibility)
    _add_button("Создать и войти", func():
        world_name = name_field.text.strip_edges()
        world_password = password_field.text
        is_public = visibility.button_pressed
        if world_name.is_empty():
            _add_status("Укажи имя мира.")
            return
        if not is_public and world_password.is_empty():
            _add_status("Для закрытого мира задай пароль.")
            return
        _host_world()
    )
    _add_button("Назад", _show_multiplayer_menu)

func _show_join_world() -> void:
    _clear_page("ПОДКЛЮЧИТЬСЯ", "Введи адрес комнаты в формате IP:порт и пароль")
    var name_field := _add_field("Твоё имя", player_name)
    var code_field := _add_field("Код мира (IP:порт)", "")
    var password_field := _add_field("Пароль мира", "", true)
    _add_button("Подключиться", func():
        player_name = name_field.text.strip_edges()
        var parts := code_field.text.strip_edges().split(":")
        if parts.size() != 2 or not parts[1].is_valid_int():
            _add_status("Код должен выглядеть как 192.168.1.10:27015.")
            return
        if player_name.is_empty():
            _add_status("Укажи имя игрока.")
            return
        _join_world(parts[0], int(parts[1]), password_field.text)
    )
    _add_button("Назад", _show_multiplayer_menu)

func _show_quick_match() -> void:
    _clear_page("БЫСТРАЯ ИГРА", "Открытые миры, доступные для подключения")
    _add_status("Каталог открытых серверов ещё не подключён. Сейчас можно создать открытый мир и подключаться к нему по IP:порт. Автоматический поиск заработает после запуска общего сервиса комнат.")
    _add_button("Создать открытый мир", func():
        is_public = true
        world_name = "Открытый мир"
        world_password = ""
        _host_world()
    )
    _add_button("Назад", _show_multiplayer_menu)

func _show_settings() -> void:
    _clear_page("НАСТРОЙКИ", "Локальные параметры")
    var name_field := _add_field("Имя игрока", player_name)
    _add_button("Сохранить", func():
        player_name = name_field.text.strip_edges()
        if player_name.is_empty():
            player_name = "Игрок"
        _show_main_menu()
    )
    _add_button("Назад", _show_main_menu)

func _start_solo() -> void:
    _launch_game("Одиночная игра")

func _host_world() -> void:
    var peer := ENetMultiplayerPeer.new()
    var error := peer.create_server(DEFAULT_PORT, MAX_PLAYERS - 1)
    if error != OK:
        _add_status("Не удалось создать сервер. Код ошибки: %s" % error)
        return
    multiplayer.multiplayer_peer = peer
    server_password = "" if is_public else world_password
    authenticated.clear()
    remote_positions.clear()
    remote_names.clear()
    _launch_game("Мир: %s" % world_name)
    var address := "127.0.0.1"
    for candidate in IP.get_local_addresses():
        if candidate.count(".") == 3 and not candidate.begins_with("127.") and not candidate.begins_with("169.254."):
            address = candidate
            break
    _show_room_code("%s:%d" % [address, DEFAULT_PORT], is_public)

func _join_world(address: String, port: int, password: String) -> void:
    var peer := ENetMultiplayerPeer.new()
    var error := peer.create_client(address, port)
    if error != OK:
        _add_status("Не удалось начать подключение. Код ошибки: %s" % error)
        return
    multiplayer.multiplayer_peer = peer
    multiplayer.connected_to_server.connect(func():
        rpc_id(1, "_request_join", player_name, password)
    , CONNECT_ONE_SHOT)
    multiplayer.connection_failed.connect(func():
        _show_multiplayer_menu()
    , CONNECT_ONE_SHOT)
    _add_status("Подключаемся к %s:%d…" % [address, port])

func _show_room_code(code: String, public_room: bool) -> void:
    _clear_page("МИР СОЗДАН", "Открытый мир" if public_room else "Закрытый мир")
    var code_label := Label.new()
    code_label.text = "Код подключения:\n" + code
    code_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    code_label.add_theme_font_size_override("font_size", 24)
    code_label.add_theme_color_override("font_color", Color("#8fe5dc"))
    page.add_child(code_label)
    _add_status("Передай игрокам IP:порт и пароль, если мир закрытый. Для подключения через интернет может понадобиться проброс UDP-порта 27015 на роутере.")
    _add_button("Открыть игру", func(): _launch_game("Мир: %s" % world_name))
    _add_button("В меню", _disconnect_to_menu)

func _launch_game(label: String) -> void:
    ui.visible = false
    if game_node:
        game_node.queue_free()
    game_node = Node2D.new()
    game_node.set_script(GAME_SCRIPT)
    add_child(game_node)
    game_node.set_meta("room_label", label)
    game_node.set("remote_players", remote_positions.duplicate())

func _disconnect_to_menu() -> void:
    multiplayer.multiplayer_peer = null
    if game_node:
        game_node.queue_free()
        game_node = null
    ui.visible = true
    _show_main_menu()

func _process(delta: float) -> void:
    if game_node == null or multiplayer.multiplayer_peer == null:
        return
    sync_elapsed += delta
    if sync_elapsed < 0.08:
        return
    sync_elapsed = 0.0
    var position: Vector2 = game_node.get("player_position")
    if multiplayer.is_server():
        remote_positions[1] = position
        rpc("_relay_position", 1, position, player_name)
    else:
        rpc_id(1, "_sync_position", position)

@rpc("any_peer", "call_remote", "reliable")
func _request_join(name: String, password: String) -> void:
    if not multiplayer.is_server():
        return
    var peer_id := multiplayer.get_remote_sender_id()
    if (not is_public and password != server_password) or name.strip_edges().is_empty():
        rpc_id(peer_id, "_join_result", false, "Неверный пароль или имя игрока.")
        multiplayer.multiplayer_peer.disconnect_peer(peer_id)
        return
    authenticated[peer_id] = true
    remote_names[peer_id] = name
    rpc_id(peer_id, "_join_result", true, world_name)
    rpc("_relay_position", peer_id, Vector2(150, 570), name)

@rpc("authority", "call_remote", "reliable")
func _join_result(success: bool, result: String) -> void:
    if success:
        _launch_game("Мир: %s" % result)
    else:
        _show_multiplayer_menu()
        _add_status(result)

@rpc("any_peer", "call_remote", "unreliable")
func _sync_position(position: Vector2) -> void:
    if not multiplayer.is_server():
        return
    var peer_id := multiplayer.get_remote_sender_id()
    if not authenticated.get(peer_id, false):
        return
    remote_positions[peer_id] = position
    if game_node:
        game_node.set("remote_players", remote_positions.duplicate())
    rpc("_relay_position", peer_id, position, remote_names.get(peer_id, "Игрок"))

@rpc("authority", "call_remote", "unreliable")
func _relay_position(peer_id: int, position: Vector2, name: String) -> void:
    if peer_id == multiplayer.get_unique_id():
        return
    remote_positions[peer_id] = position
    remote_names[peer_id] = name
    if game_node:
        game_node.set("remote_players", remote_positions.duplicate())
