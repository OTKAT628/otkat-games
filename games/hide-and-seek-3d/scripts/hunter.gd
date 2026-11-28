extends CharacterBody3D
class_name MallHunter

signal caught_survivor

const HUNT_SPEED := 3.7
const PATROL_SPEED := 2.1
const DETECTION_RANGE := 19.0
const CATCH_RANGE := 1.55
const GRAVITY := 18.0

var target: HideAndSeekPlayer
var state := "patrol"
var patrol_points: Array[Vector3] = [Vector3(-22, 0, -15), Vector3(22, 0, -15), Vector3(22, 0, 15), Vector3(-22, 0, 15)]
var patrol_index := 0
var search_position := Vector3.ZERO
var search_time := 0.0
var avoid_direction := 1.0
var frozen_time := 0.0
var bagged_time := 0.0
var lure_time := 0.0
var lure_position := Vector3.ZERO

func _ready() -> void:
	_build_hunter()

func _build_hunter() -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.48
	capsule.height = 2.05
	var collision := CollisionShape3D.new()
	collision.shape = capsule
	collision.position.y = 1.02
	add_child(collision)

	var visual := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.46
	mesh.height = 2.0
	visual.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#492f3c")
	mat.roughness = 0.62
	visual.material_override = mat
	visual.position.y = 1.0
	add_child(visual)

	var eye := OmniLight3D.new()
	eye.position = Vector3(0, 1.55, -0.35)
	eye.light_color = Color("#d65b54")
	eye.light_energy = 0.45
	eye.omni_range = 2.8
	add_child(eye)

func _physics_process(delta: float) -> void:
	frozen_time = maxf(0.0, frozen_time - delta)
	bagged_time = maxf(0.0, bagged_time - delta)
	lure_time = maxf(0.0, lure_time - delta)
	if frozen_time > 0.0:
		velocity = Vector3.ZERO
		return
	if lure_time > 0.0:
		_move_toward(lure_position, PATROL_SPEED * 1.25, delta)
		if global_position.distance_to(lure_position) < 1.1:
			lure_time = 0.0
			state = "investigate"
			search_position = lure_position
			search_time = 2.5
		return
	if not is_instance_valid(target):
		return
	var target_pos := target.global_position
	var distance := global_position.distance_to(target_pos)
	if target.disguised:
		if distance < 3.0:
			state = "investigate"
			search_position = target.disguise_anchor
			search_time = 3.5
		else:
			_patrol(delta)
			return
	var effective_detection_range := DETECTION_RANGE
	if target.is_crouching:
		effective_detection_range = 10.0
	elif target.is_sprinting:
		effective_detection_range = 25.0
	if not target.disguised and distance <= effective_detection_range and _can_see_target():
		state = "chase"
		search_position = target_pos
	elif state == "chase":
		state = "investigate"
		search_time = 4.0

	if target.disguised and distance <= 1.45:
		caught_survivor.emit()
		return

	match state:
		"chase":
			var speed := HUNT_SPEED * (0.55 if bagged_time > 0.0 else 1.0)
			_move_toward(target_pos, speed, delta)
			if distance <= CATCH_RANGE:
				caught_survivor.emit()
		"investigate":
			_move_toward(search_position, PATROL_SPEED, delta)
			search_time -= delta
			if search_time <= 0.0 or global_position.distance_to(search_position) < 1.0:
				state = "patrol"
		_:
			_patrol(delta)

func hear_noise(point: Vector3, radius: float) -> void:
	if global_position.distance_to(point) <= radius and lure_time <= 0.0:
		state = "investigate"
		search_position = point
		search_time = 3.0

func investigate_position(point: Vector3, duration: float) -> void:
	lure_position = point
	lure_time = duration
	state = "investigate"

func apply_freeze(duration: float) -> void:
	frozen_time = maxf(frozen_time, duration)

func apply_bag(duration: float) -> void:
	bagged_time = maxf(bagged_time, duration)

func _can_see_target() -> bool:
	var origin := global_position + Vector3.UP * 1.15
	var target_height := 0.72 if target.is_crouching else 1.0
	var destination := target.global_position + Vector3.UP * target_height
	var query := PhysicsRayQueryParameters3D.create(origin, destination)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == target

func _patrol(delta: float) -> void:
	var point := patrol_points[patrol_index]
	if global_position.distance_to(point) < 1.2:
		patrol_index = (patrol_index + 1) % patrol_points.size()
		point = patrol_points[patrol_index]
	_move_toward(point, PATROL_SPEED, delta)

func _move_toward(point: Vector3, speed: float, delta: float) -> void:
	var flat := point - global_position
	flat.y = 0.0
	if flat.length() < 0.12:
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		var direction := flat.normalized()
		var origin := global_position + Vector3.UP * 0.9
		var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 1.6)
		query.exclude = [get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			direction = (direction + Vector3(direction.z, 0, -direction.x) * avoid_direction * 0.9).normalized()
			avoid_direction *= -1.0
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		look_at(global_position + direction, Vector3.UP)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.2
	move_and_slide()
