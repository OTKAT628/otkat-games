extends Node3D
class_name OtkatWeaponRuntime
## Reusable offline prototype for player-controlled hunter weapons.
## Online hits must be revalidated by the authoritative match server.

signal weapon_fired(weapon_id: String, ammo_left: int)
signal target_hit(target: Object, weapon_id: String)
signal weapon_blocked(reason: String)
signal ammo_changed(current: int, reserve: int)

const Registry = preload("res://scripts/arsenal_registry.gd")
const MAGAZINE_SIZES := {
	"shotgun": 6, "pump_shotgun": 6, "sidearm": 12, "service_sidearm": 12,
	"toy_blaster": 16, "launcher": 4, "energy_sidearm": 10, "energy_blade": 0,
	"plasma_rifle": 24, "stun_emitter": 5, "arcane_focus": 8, "sonic_relic": 6
}

var world_id := "realistic"
var weapon_data: Dictionary = {}
var ammo_in_magazine := 0
var reserve_ammo := 0
var cooldown_left := 0.0
var is_reloading := false

func _process(delta: float) -> void:
	cooldown_left = maxf(0.0, cooldown_left - delta)

func equip(world: String, weapon_id: String) -> bool:
	var candidate := Registry.get_weapon(world, weapon_id)
	if candidate.is_empty():
		weapon_blocked.emit("Оружие не найдено в коллекции этого мира.")
		return false
	world_id = world
	weapon_data = candidate
	var magazine_size := int(MAGAZINE_SIZES.get(str(candidate.type), 8))
	ammo_in_magazine = magazine_size
	reserve_ammo = magazine_size * 4
	is_reloading = false
	ammo_changed.emit(ammo_in_magazine, reserve_ammo)
	return true

func try_fire(origin: Vector3, direction: Vector3) -> bool:
	if weapon_data.is_empty():
		weapon_blocked.emit("Сначала выбери оружие.")
		return false
	if is_reloading or cooldown_left > 0.0:
		return false
	if ammo_in_magazine <= 0 and int(MAGAZINE_SIZES.get(str(weapon_data.type), 8)) > 0:
		weapon_blocked.emit("Магазин пуст. Перезаряди оружие.")
		return false

	cooldown_left = float(weapon_data.get("cooldown", 0.5))
	var magazine_size := int(MAGAZINE_SIZES.get(str(weapon_data.type), 8))
	if magazine_size > 0:
		ammo_in_magazine -= 1
	ammo_changed.emit(ammo_in_magazine, reserve_ammo)
	weapon_fired.emit(str(weapon_data.id), ammo_in_magazine)

	var reach := float(weapon_data.get("range", 20.0))
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction.normalized() * reach)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		target_hit.emit(hit.get("collider"), str(weapon_data.id))
	return true

func reload_weapon() -> void:
	if weapon_data.is_empty() or is_reloading:
		return
	var magazine_size := int(MAGAZINE_SIZES.get(str(weapon_data.type), 8))
	if magazine_size <= 0 or ammo_in_magazine >= magazine_size or reserve_ammo <= 0:
		return
	is_reloading = true
	await get_tree().create_timer(1.65).timeout
	var needed := magazine_size - ammo_in_magazine
	var loaded := mini(needed, reserve_ammo)
	ammo_in_magazine += loaded
	reserve_ammo -= loaded
	is_reloading = false
	ammo_changed.emit(ammo_in_magazine, reserve_ammo)
