extends Node2D

const CELL := 48
const MAP_W := 22
const MAP_H := 12
var player := Vector2i(10, 6)
var resources: Array[Dictionary] = []
var inventory := {"wood": 0, "stone": 0, "food": 3}
var health := 100
var hunger := 100.0
var day := 1
var elapsed := 0.0
var move_cooldown := 0.0
var hud: Label
var message := "Исследуй остров. WASD/стрелки — движение, E — собрать ресурс."

func _ready() -> void:
	randomize()
	for i in range(45):
		var p := Vector2i(randi_range(1, MAP_W-2), randi_range(1, MAP_H-2))
		if p != player:
			resources.append({"pos": p, "kind": ["tree","rock","berry"][randi_range(0,2)]})
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(18, 14)
	hud.add_theme_font_size_override("font_size", 18)
	hud.add_theme_color_override("font_color", Color.WHITE)
	layer.add_child(hud)
	_update_hud()

func _process(delta: float) -> void:
	elapsed += delta
	move_cooldown = maxf(0.0, move_cooldown - delta)
	hunger = maxf(0.0, hunger - delta * 0.55)
	if hunger <= 0:
		health = maxi(0, health - int(delta * 2.0))
	if elapsed > 90.0:
		day += 1
		elapsed = 0.0
		hunger = maxf(0.0, hunger - 8.0)
		message = "Наступил день %d. Следи за запасами еды." % day
	_update_hud()
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var dir := Vector2i.ZERO
	match event.keycode:
		KEY_W, KEY_UP: dir = Vector2i.UP
		KEY_S, KEY_DOWN: dir = Vector2i.DOWN
		KEY_A, KEY_LEFT: dir = Vector2i.LEFT
		KEY_D, KEY_RIGHT: dir = Vector2i.RIGHT
		KEY_E:
			_gather()
			return
		KEY_F:
			_eat()
			return
		KEY_C:
			_craft()
			return
	if dir != Vector2i.ZERO and move_cooldown <= 0:
		player.x = clampi(player.x + dir.x, 0, MAP_W-1)
		player.y = clampi(player.y + dir.y, 0, MAP_H-1)
		move_cooldown = 0.12

func _gather() -> void:
	var found := -1
	for i in range(resources.size()):
		if resources[i].pos.distance_to(player) <= 1.2:
			found = i
			break
	if found < 0:
		message = "Рядом нет ресурса. Подойди ближе."
		return
	var item: Dictionary = resources[found]
	match item.kind:
		"tree":
			inventory.wood += 1
			message = "Собрано дерево."
		"rock":
			inventory.stone += 1
			message = "Собран камень."
		"berry":
			inventory.food += 1
			message = "Собраны ягоды."
	resources.remove_at(found)
	_update_hud()

func _eat() -> void:
	if inventory.food <= 0:
		message = "Еды нет. Найди кусты с ягодами."
		return
	inventory.food -= 1
	hunger = minf(100.0, hunger + 35.0)
	message = "Ты поел. Голод уменьшился."

func _craft() -> void:
	if inventory.wood >= 3 and inventory.stone >= 2:
		inventory.wood -= 3
		inventory.stone -= 2
		health = mini(100, health + 25)
		message = "Ты построил укрытие и восстановил здоровье."
	else:
		message = "Для укрытия нужно 3 дерева и 2 камня."

func _update_hud() -> void:
	if hud:
		hud.text = "OTKAT WILD FRONTIER   День %d   Здоровье %d   Голод %d\nДерево %d   Камень %d   Еда %d\n%s\nE — собрать   F — поесть   C — построить укрытие" % [day, health, int(hunger), inventory.wood, inventory.stone, inventory.food, message]

func _draw() -> void:
	var origin := Vector2(24, 112)
	for y in range(MAP_H):
		for x in range(MAP_W):
			var rect := Rect2(origin + Vector2(x*CELL, y*CELL), Vector2(CELL-2, CELL-2))
			draw_rect(rect, Color("#315a49") if (x+y)%2==0 else Color("#294f40"))
	for item in resources:
		var p: Vector2 = origin + Vector2(item.pos.x*CELL + CELL/2, item.pos.y*CELL + CELL/2)
		var color := Color("#4aa66a")
		if item.kind == "rock": color = Color("#a5abb4")
		if item.kind == "berry": color = Color("#d66a88")
		draw_circle(p, 13, color)
	var pp: Vector2 = origin + Vector2(player.x*CELL + CELL/2, player.y*CELL + CELL/2)
	draw_circle(pp, 15, Color("#f4d36d"))
	draw_circle(pp, 5, Color("#fff4d0"))
