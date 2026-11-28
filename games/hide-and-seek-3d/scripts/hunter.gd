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
	elif distance <= DETECTION_RANGE:
		state = "chase"
		search_position = target_pos
	elif state == "chase":
		state = "investigate"
		search_time = 4.0

	match state:
		"chase":
			_move_toward(target_pos, HUNT_SPEED, delta)
			if distance <= CATCH_RANGE:
				caught_survivor.emit()
		"investigate":
			_move_toward(search_position, PATROL_SPEED, delta)
			search_time -= delta
			if search_time <= 0.0 or global_position.distance_to(search_position) < 1.0:
				state = "patrol"
		_:
			_patrol(delta)

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
		var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 1.6, [self])
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
