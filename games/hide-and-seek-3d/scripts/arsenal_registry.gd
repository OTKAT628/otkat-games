extends RefCounted
class_name OtkatArsenalRegistry
## Original OTKAT equipment catalog. All prices are in-game credits, never real money.

const RARITIES := {
	"common": {"label": "Обычная", "multiplier": 1.0, "color": "#a8adb4"},
	"uncommon": {"label": "Необычная", "multiplier": 1.35, "color": "#65b879"},
	"rare": {"label": "Редкая", "multiplier": 1.8, "color": "#5798e8"},
	"epic": {"label": "Эпическая", "multiplier": 2.7, "color": "#a878df"},
	"legendary": {"label": "Легендарная", "multiplier": 4.5, "color": "#e9b84f"},
	"mythic": {"label": "Мифическая", "multiplier": 8.0, "color": "#e87568"}
}

const WORLD_NAMES := {
	"apocalypse": "Апокалипсис",
	"cartoon": "Мультяшный мир",
	"anime": "Аниме-мир",
	"realistic": "Реалистичный мир",
	"scifi": "Научная фантастика",
	"mystery": "Мистика"
}

const CATALOG := {
	"apocalypse": [
		{"id":"ap_rivet","name":"Rivet-12","type":"shotgun","rarity":"rare","value":900,"damage":34,"cooldown":0.95,"range":15.0,"skins":[
			{"id":"ap_rivet_rust","name":"Ржавый уцелевший","rarity":"common","value":80},
			{"id":"ap_rivet_bunker","name":"Бункерная сталь","rarity":"epic","value":520},
			{"id":"ap_rivet_ash","name":"Пепельный шторм","rarity":"legendary","value":1250}]},
		{"id":"ap_scout","name":"Scout-9","type":"sidearm","rarity":"uncommon","value":420,"damage":18,"cooldown":0.32,"range":24.0,"skins":[
			{"id":"ap_scout_tape","name":"Изолента","rarity":"common","value":55},
			{"id":"ap_scout_wasteland","name":"Пустошь","rarity":"rare","value":240},
			{"id":"ap_scout_redline","name":"Красная черта","rarity":"epic","value":480}]}
	],
	"cartoon": [
		{"id":"ca_popper","name":"Popper Blaster","type":"toy_blaster","rarity":"rare","value":850,"damage":20,"cooldown":0.48,"range":22.0,"skins":[
			{"id":"ca_popper_candy","name":"Карамельный взрыв","rarity":"uncommon","value":130},
			{"id":"ca_popper_comic","name":"Комикс-панель","rarity":"epic","value":470},
			{"id":"ca_popper_rainbow","name":"Радужный хаос","rarity":"legendary","value":1100}]},
		{"id":"ca_squeak","name":"Squeak-двойка","type":"launcher","rarity":"epic","value":1450,"damage":28,"cooldown":1.4,"range":18.0,"skins":[
			{"id":"ca_squeak_foam","name":"Пенная игрушка","rarity":"common","value":70},
			{"id":"ca_squeak_bubble","name":"Пузырьковый","rarity":"rare","value":310},
			{"id":"ca_squeak_gold","name":"Золотой розыгрыш","rarity":"mythic","value":2200}]}
	],
	"anime": [
		{"id":"an_kitsune","name":"Kitsune-6","type":"energy_sidearm","rarity":"epic","value":1600,"damage":22,"cooldown":0.38,"range":28.0,"skins":[
			{"id":"an_kitsune_ember","name":"Алый лепесток","rarity":"rare","value":330},
			{"id":"an_kitsune_moon","name":"Лунная печать","rarity":"epic","value":590},
			{"id":"an_kitsune_spirit","name":"Дух девяти хвостов","rarity":"legendary","value":1450}]},
		{"id":"an_ronin","name":"Ronin Edge","type":"energy_blade","rarity":"legendary","value":2600,"damage":42,"cooldown":0.82,"range":3.2,"skins":[
			{"id":"an_ronin_steel","name":"Старая сталь","rarity":"uncommon","value":160},
			{"id":"an_ronin_sakura","name":"Сакура","rarity":"epic","value":640},
			{"id":"an_ronin_void","name":"Пустотный клинок","rarity":"mythic","value":2900}]}
	],
	"realistic": [
		{"id":"re_vanguard","name":"Vanguard-12","type":"pump_shotgun","rarity":"rare","value":1250,"damage":32,"cooldown":0.9,"range":16.0,"skins":[
			{"id":"re_vanguard_field","name":"Полевой камуфляж","rarity":"common","value":100},
			{"id":"re_vanguard_urban","name":"Городской пиксель","rarity":"rare","value":390},
			{"id":"re_vanguard_obsidian","name":"Обсидиан","rarity":"legendary","value":1600}]},
		{"id":"re_sentinel","name":"Sentinel-45","type":"service_sidearm","rarity":"uncommon","value":680,"damage":19,"cooldown":0.34,"range":26.0,"skins":[
			{"id":"re_sentinel_graphite","name":"Графит","rarity":"common","value":65},
			{"id":"re_sentinel_sand","name":"Песчаная буря","rarity":"rare","value":280},
			{"id":"re_sentinel_chrome","name":"Хромированный протокол","rarity":"epic","value":720}]}
	],
	"scifi": [
		{"id":"sf_arc","name":"ARC-Vector","type":"plasma_rifle","rarity":"epic","value":1900,"damage":24,"cooldown":0.25,"range":34.0,"skins":[
			{"id":"sf_arc_circuit","name":"Схема","rarity":"rare","value":360},
			{"id":"sf_arc_neon","name":"Неоновый контур","rarity":"epic","value":680},
			{"id":"sf_arc_singularity","name":"Сингулярность","rarity":"mythic","value":3100}]},
		{"id":"sf_pulse","name":"Pulse Hammer","type":"stun_emitter","rarity":"legendary","value":2800,"damage":12,"cooldown":1.6,"range":10.0,"skins":[
			{"id":"sf_pulse_cobalt","name":"Кобальтовый импульс","rarity":"uncommon","value":180},
			{"id":"sf_pulse_overload","name":"Перегрузка","rarity":"epic","value":760},
			{"id":"sf_pulse_event","name":"Нулевая точка","rarity":"legendary","value":1700}]}
	],
	"mystery": [
		{"id":"my_reliquary","name":"Реликварий","type":"arcane_focus","rarity":"epic","value":1750,"damage":25,"cooldown":0.65,"range":20.0,"skins":[
			{"id":"my_reliquary_bone","name":"Костяная вязь","rarity":"rare","value":340},
			{"id":"my_reliquary_veil","name":"Покров теней","rarity":"epic","value":700},
			{"id":"my_reliquary_crown","name":"Корона безумия","rarity":"mythic","value":3000}]},
		{"id":"my_warden","name":"Warden Bell","type":"sonic_relic","rarity":"rare","value":1050,"damage":16,"cooldown":1.1,"range":18.0,"skins":[
			{"id":"my_warden_iron","name":"Железный звон","rarity":"common","value":90},
			{"id":"my_warden_crypt","name":"Крипта","rarity":"rare","value":300},
			{"id":"my_warden_eclipse","name":"Затмение","rarity":"legendary","value":1350}]}
	]
}

static func get_world_weapons(world_id: String) -> Array:
	return CATALOG.get(world_id, []).duplicate(true)

static func get_weapon(world_id: String, weapon_id: String) -> Dictionary:
	for weapon in CATALOG.get(world_id, []):
		if weapon.id == weapon_id:
			return weapon.duplicate(true)
	return {}

static func get_skin(world_id: String, weapon_id: String, skin_id: String) -> Dictionary:
	var weapon := get_weapon(world_id, weapon_id)
	for skin in weapon.get("skins", []):
		if skin.id == skin_id:
			return skin.duplicate(true)
	return {}

static func get_rarity_label(rarity_id: String) -> String:
	return str(RARITIES.get(rarity_id, {}).get("label", "Неизвестно"))

static func get_item_value(world_id: String, weapon_id: String, skin_id: String = "") -> int:
	var weapon := get_weapon(world_id, weapon_id)
	if weapon.is_empty():
		return 0
	if skin_id.is_empty():
		return int(weapon.value)
	var skin := get_skin(world_id, weapon_id, skin_id)
	return int(skin.get("value", 0))
