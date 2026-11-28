extends RefCounted
class_name OtkatCosmeticInventory
## Local prototype inventory. Server-authoritative ownership is required for online play.

const SAVE_PATH := "user://otkat_hide_seek_inventory.json"

var owned_weapons: Array[String] = []
var owned_skins: Array[String] = []
var equipped_skins: Dictionary = {}
var credits: int = 0

func _init() -> void:
	load_inventory()

func owns_weapon(weapon_id: String) -> bool:
	return owned_weapons.has(weapon_id)

func owns_skin(skin_id: String) -> bool:
	return owned_skins.has(skin_id)

func unlock_weapon(weapon_id: String) -> void:
	if not owned_weapons.has(weapon_id):
		owned_weapons.append(weapon_id)
		save_inventory()

func unlock_skin(skin_id: String) -> void:
	if not owned_skins.has(skin_id):
		owned_skins.append(skin_id)
		save_inventory()

func equip_skin(weapon_id: String, skin_id: String) -> bool:
	if not owns_weapon(weapon_id) or not owns_skin(skin_id):
		return false
	equipped_skins[weapon_id] = skin_id
	save_inventory()
	return true

func get_equipped_skin(weapon_id: String) -> String:
	return str(equipped_skins.get(weapon_id, ""))

func add_credits(amount: int) -> void:
	credits = maxi(0, credits + amount)
	save_inventory()

func spend_credits(amount: int) -> bool:
	if amount < 0 or credits < amount:
		return false
	credits -= amount
	save_inventory()
	return true

func save_inventory() -> void:
	var payload := {
		"version": 1,
		"credits": credits,
		"owned_weapons": owned_weapons,
		"owned_skins": owned_skins,
		"equipped_skins": equipped_skins
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload))

func load_inventory() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	credits = maxi(0, int(parsed.get("credits", 0)))
	owned_weapons.clear()
	for item in parsed.get("owned_weapons", []):
		owned_weapons.append(str(item))
	owned_skins.clear()
	for item in parsed.get("owned_skins", []):
		owned_skins.append(str(item))
	equipped_skins = parsed.get("equipped_skins", {}).duplicate(true)
