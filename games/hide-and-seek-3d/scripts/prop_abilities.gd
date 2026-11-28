extends Node
class_name OtkatPropAbilities
## Prototype abilities for the survivor/prop role. Visual/audio feedback is provided by signals.

signal decoy_created(position: Vector3, duration: float)
signal hunter_blinded(duration: float)
signal ability_used(ability_id: String, cooldown: float)
signal ability_blocked(reason: String)

const ABILITIES := {
	"decoy": {"cooldown": 24.0, "duration": 7.0},
	"freeze": {"cooldown": 32.0, "duration": 2.4},
	"blind": {"cooldown": 38.0, "duration": 3.0}
}

var cooldowns: Dictionary = {}

func _process(delta: float) -> void:
	for ability_id in cooldowns.keys():
		cooldowns[ability_id] = maxf(0.0, float(cooldowns[ability_id]) - delta)

func get_cooldown_left(ability_id: String) -> float:
	return float(cooldowns.get(ability_id, 0.0))

func use_ability(ability_id: String, hunter: Node3D = null) -> bool:
	if not ABILITIES.has(ability_id):
		ability_blocked.emit("Неизвестная способность.")
		return false
	if get_cooldown_left(ability_id) > 0.0:
		ability_blocked.emit("Способность ещё перезаряжается.")
		return false
	if ability_id != "decoy" and not is_instance_valid(hunter):
		ability_blocked.emit("Охотник пока не найден.")
		return false

	var data: Dictionary = ABILITIES[ability_id]
	var duration := float(data.duration)
	match ability_id:
		"decoy":
			decoy_created.emit(global_position, duration)
		"freeze":
			var was_processing := hunter.is_physics_processing()
			hunter.set_physics_process(false)
			await get_tree().create_timer(duration).timeout
			if is_instance_valid(hunter):
				hunter.set_physics_process(was_processing)
		"blind":
			hunter_blinded.emit(duration)

	var cooldown := float(data.cooldown)
	cooldowns[ability_id] = cooldown
	ability_used.emit(ability_id, cooldown)
	return true
