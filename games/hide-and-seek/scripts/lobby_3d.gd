extends Node3D

const SKIN_COLORS = [Color("#59c7d9"),Color("#e85cbd"),Color("#6aab68"),Color("#54515e"),Color("#e6b84f"),Color("#8d91e8")]
var config: Dictionary = {}
var ui: CanvasLayer
var panel: VBoxContainer
var avatar: Node3D
var fly_mode := false
var fly_camera: Camera3D
var yaw := 0.0
var pitch := -0.15

func _ready() -> void:
 config = get_tree().get_meta("otkat_lobby_config", {})
 _build_world()
 _build_ui()
 _show_waiting()

func _material(color: Color) -> StandardMaterial3D:
 var m := StandardMaterial3D.new()
 m.albedo_color = color
 m.roughness = 0.75
 return m

func _box(pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
 var mesh := MeshInstance3D.new()
 var shape := BoxMesh.new()
 shape.size = size
 mesh.mesh = shape
 mesh.position = pos
 mesh.material_override = _material(color)
 return mesh

func _build_world() -> void:
 var floor := MeshInstance3D.new()
 var plane := PlaneMesh.new()
 plane.size = Vector2(54,54)
 floor.mesh = plane
 floor.material_override = _material(Color("#26394a"))
 add_child(floor)
 var env := WorldEnvironment.new()
 var e := Environment.new()
 e.background_mode = Environment.BG_SKY
 e.sky = Sky.new()
 e.sky.sky_material = ProceduralSkyMaterial.new()
 e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 e.ambient_light_color = Color("#a6c1d2")
 e.ambient_light_energy = 0.8
 env.environment = e
 add_child(env)
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-48,-30,0)
 add_child(sun)
 for i in range(16):
  var a := TAU * float(i) / 16.0
  add_child(_box(Vector3(cos(a)*19,2,sin(a)*19),Vector3(1.1,4,1.1),Color("#56748a")))
 # Two prominent interactive-looking portals: map gallery and item gallery.
 _portal(Vector3(-8,0,-5),Color("#42c6e7"),"КАРТЫ")
 _portal(Vector3(8,0,-5),Color("#bd78e5"),"ПРЕДМЕТЫ")
 add_child(_box(Vector3(0,0.2,0),Vector3(10,0.4,6),Color("#344f66")))
 avatar = Node3D.new()
 avatar.position = Vector3(0,0,6)
 var body := MeshInstance3D.new()
 var capsule := CapsuleMesh.new()
 capsule.radius = 0.48
 capsule.height = 1.8
 body.mesh = capsule
 body.position.y = 0.9
 var skin := int(config.get("skin_index",0))
 body.material_override = _material(SKIN_COLORS[clampi(skin,0,SKIN_COLORS.size()-1)])
 avatar.add_child(body)
 var head := MeshInstance3D.new()
 var sphere := SphereMesh.new()
 sphere.radius = 0.32
 head.mesh = sphere
 head.position.y = 1.95
 head.material_override = _material(Color("#eac5a5"))
 avatar.add_child(head)
 add_child(avatar)
 var camera := Camera3D.new()
 camera.position = Vector3(0,5,11)
 camera.look_at(Vector3(0,1,0),Vector3.UP)
 avatar.add_child(camera)
 camera.current = true

func _portal(pos: Vector3, color: Color, label: String) -> void:
 var ring := MeshInstance3D.new()
 var torus := TorusMesh.new()
 torus.inner_radius = 1.25
 torus.outer_radius = 1.5
 ring.mesh = torus
 ring.position = pos + Vector3(0,2,0)
 ring.material_override = _material(color)
 add_child(ring)
 add_child(_box(pos+Vector3(0,0.1,0),Vector3(3.2,0.2,3.2),color.darkened(0.45)))
 var sign := Label3D.new()
 sign.text = label
 sign.position = pos + Vector3(0,4,0)
 sign.font_size = 48
 add_child(sign)

func _build_ui() -> void:
 ui = CanvasLayer.new()
 add_child(ui)
 var shade := ColorRect.new()
 shade.color = Color(0.04,0.07,0.11,0.84)
 shade.position = Vector2(20,20)
 shade.size = Vector2(430,560)
 ui.add_child(shade)
 panel = VBoxContainer.new()
 panel.position = Vector2(38,35)
 panel.size = Vector2(395,530)
 panel.add_theme_constant_override("separation",8)
 ui.add_child(panel)

func _clear(title: String, subtitle := "") -> void:
 for c in panel.get_children():
  c.queue_free()
 var h := Label.new()
 h.text = title
 h.add_theme_font_size_override("font_size",26)
 panel.add_child(h)
 if subtitle != "":
  var s := Label.new()
  s.text = subtitle
  s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  panel.add_child(s)

func _button(text: String, callback: Callable) -> void:
 var b := Button.new()
 b.text = text
 b.custom_minimum_size = Vector2(380,42)
 b.pressed.connect(callback)
 panel.add_child(b)

func _show_waiting() -> void:
 _clear("3D-ЛОББИ ОЖИДАНИЯ","Комната: %s\n%s · игроки: 1/8\nПерсонаж: %s"%[config.get("room_name","Комната"),"Открытая" if config.get("public",false) else "Закрытая","Выбранный скин"])
 _button("Портал: осмотреть карты", _show_maps)
 _button("Портал: каталог предметов", _show_items)
 _button("Изменить скин персонажа", _show_skins)
 _button("Свободный полёт над локацией", _toggle_fly)
 _button("Игроки и приглашения", _show_players)
 _button("Настройки раунда", _show_settings)
 _button("Начать раунд", _start_round)
 _button("Выйти в 2D-меню", _back_to_menu)

func _show_maps() -> void:
 _clear("ГАЛЕРЕЯ КАРТ","Портал предварительного просмотра")
 for map_name in ["Туманный лес","Неоновый квартал","Последний рейс · самолёт","Фабрика игрушек","Святилище луны","Город героев","Северное королевство"]:
  _button(map_name, func(): config["map_name"] = map_name; _show_maps())
 _button("Назад в лобби", _show_waiting)

func _show_items() -> void:
 _clear("КАТАЛОГ ПРЕДМЕТОВ","В матче рулетка предложит 4–6 объектов именно с выбранной карты")
 var items := ["Ящики и контейнеры","Мебель и декор","Транспорт и обломки","Растения и камни","Освещение и техника","Уникальные объекты карты"]
 for item in items:
  var l := Label.new()
  l.text = "• " + item
  panel.add_child(l)
 _button("Назад в лобби", _show_waiting)

func _show_skins() -> void:
 _clear("СКИНЫ ПЕРСОНАЖА","Выбери облик прямо в 3D-лобби")
 for i in range(SKIN_COLORS.size()):
  var idx := i
  _button("Скин %d%s"%[i+1," · выбран" if int(config.get("skin_index",0))==i else ""],func():
   config["skin_index"] = idx
   var body := avatar.get_child(0) as MeshInstance3D
   body.material_override = _material(SKIN_COLORS[idx])
   _show_skins()
  )
 _button("Назад в лобби", _show_waiting)

func _show_players() -> void:
 _clear("ИГРОКИ","Комната: %s · лимит 8"%config.get("room_name","Комната"))
 var l := Label.new()
 l.text = "1. Вы (создатель)\n\nОжидание подключений…"
 panel.add_child(l)
 _button("Скопировать код комнаты",func():DisplayServer.clipboard_set(str(config.get("room_name","Комната"))))
 _button("Назад в лобби",_show_waiting)

func _show_settings() -> void:
 _clear("НАСТРОЙКИ РАУНДА","")
 var l := Label.new()
 l.text = "Длительность: %s сек.\nПеревыборы: %s"%[config.get("duration",180),config.get("rerolls",2)]
 panel.add_child(l)
 _button("Назад в лобби",_show_waiting)

func _toggle_fly() -> void:
 fly_mode = not fly_mode
 if fly_mode:
  fly_camera = Camera3D.new()
  fly_camera.position = Vector3(0,12,20)
  fly_camera.current = true
  add_child(fly_camera)
  _clear("СВОБОДНАЯ КАМЕРА","WASD — движение · мышь — обзор · F — выйти из полёта")
  _button("Вернуться в лобби",_toggle_fly)
 else:
  if is_instance_valid(fly_camera):
   fly_camera.queue_free()
  var camera := avatar.get_node_or_null("Camera3D") as Camera3D
  if camera: camera.current = true
  _show_waiting()

func _start_round() -> void:
 _clear("КОМНАТА ГОТОВА","Раунд стартует после подключения игроков и запуска игрового сервера.")
 _button("Назад в лобби",_show_waiting)

func _back_to_menu() -> void:
 get_tree().change_scene_to_file("res://scenes/menu_2d.tscn")

func _unhandled_input(event: InputEvent) -> void:
 if fly_mode and event is InputEventKey and event.pressed:
  var move := Vector3.ZERO
  if event.keycode == KEY_W: move.z -= 1
  if event.keycode == KEY_S: move.z += 1
  if event.keycode == KEY_A: move.x -= 1
  if event.keycode == KEY_D: move.x += 1
  fly_camera.position += move * 0.8
  if event.keycode == KEY_F: _toggle_fly()
