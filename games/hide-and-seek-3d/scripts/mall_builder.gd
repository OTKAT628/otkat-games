extends Node3D
class_name AbandonedMallBuilder

var disguise_points: Array[Vector3] = []
var rng := RandomNumberGenerator.new()

func build() -> void:
	rng.seed = 6282026
	_build_lighting()
	_build_shell()
	_build_atrium()
	_build_shops()
	_build_debris()
	_build_props()
	_build_overgrowth()
	_build_atmosphere_details()

func _material(color: Color, roughness: float = 0.88, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m

func _box(name: String, size: Vector3, pos: Vector3, mat: Material, solid: bool = true) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.name = name
	visual.mesh = mesh
	visual.material_override = mat
	visual.position = pos
	add_child(visual)
	if solid:
		var body := StaticBody3D.new()
		body.name = name + "Collision"
		body.position = pos
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.add_child(shape)
		add_child(body)
	return visual

func _cylinder(name: String, radius: float, height: float, pos: Vector3, mat: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	var visual := MeshInstance3D.new()
	visual.name = name
	visual.mesh = mesh
	visual.material_override = mat
	visual.position = pos
	add_child(visual)
	var body := StaticBody3D.new()
	body.position = pos
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = height
	shape.shape = cylinder
	body.add_child(shape)
	add_child(body)

func _build_lighting() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.055, 0.075, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.22, 0.27, 0.31)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.19, 0.23, 0.22)
	env.fog_density = 0.012
	world.environment = env
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sun.light_color = Color(0.72, 0.79, 0.82)
	sun.light_energy = 0.45
	sun.shadow_enabled = true
	add_child(sun)

	for p in [Vector3(-17, 7, -12), Vector3(0, 7, -12), Vector3(17, 7, -12),
			Vector3(-17, 7, 12), Vector3(0, 7, 12), Vector3(17, 7, 12)]:
		var light := OmniLight3D.new()
		light.position = p
		light.light_color = Color(0.72, 0.84, 0.91)
		light.light_energy = 1.15
		light.omni_range = 15.0
		light.shadow_enabled = false
		add_child(light)

func _build_shell() -> void:
	var concrete := _material(Color("#42484a"))
	var floor_mat := _material(Color("#77766d"), 0.62)
	var dark := _material(Color("#20272a"))
	var glass := _material(Color(0.16, 0.29, 0.32, 0.72), 0.18, 0.22)
	var tile := _material(Color("#a5a095"), 0.48)
	_box("MallFloor", Vector3(64, 0.8, 48), Vector3(0, -0.4, 0), floor_mat)
	_box("NorthWall", Vector3(64, 10, 1), Vector3(0, 4.6, -24), concrete)
	_box("SouthWall", Vector3(64, 10, 1), Vector3(0, 4.6, 24), concrete)
	_box("WestWall", Vector3(1, 10, 48), Vector3(-32, 4.6, 0), concrete)
	_box("EastWall", Vector3(1, 10, 48), Vector3(32, 4.6, 0), concrete)
	_box("Ceiling", Vector3(64, 0.7, 48), Vector3(0, 9.6, 0), dark)
	_box("AtriumTile", Vector3(22, 0.08, 16), Vector3(0, 0.03, 0), tile, false)
	for x in [-27.0, -18.0, -9.0, 9.0, 18.0, 27.0]:
		for z in [-19.0, 19.0]:
			_cylinder("ConcretePillar", 0.65, 9.0, Vector3(x, 4.5, z), concrete)
	for x in [-31.0, 31.0]:
		_box("ShopfrontGlass", Vector3(0.12, 4.4, 9.0), Vector3(x * 0.88, 2.2, 0), glass, false)
	_box("BrokenCeilingOpening", Vector3(12, 0.15, 7), Vector3(0, 9.1, -2), dark, false)
	# Cracked floor strips and faded navigation lines.
	for x in range(-28, 29, 4):
		_box("TileSeam", Vector3(0.035, 0.012, 46), Vector3(x, 0.012, 0), dark, false)
	for z in range(-20, 21, 4):
		_box("TileSeam", Vector3(62, 0.012, 0.035), Vector3(0, 0.013, z), dark, false)

func _build_atrium() -> void:
	var rust := _material(Color("#765342"))
	var faded_blue := _material(Color("#52666a"))
	var sign_mat := _material(Color("#d0b77a"), 0.7, 0.05)
	_box("CollapsedKioskBase", Vector3(5.2, 1.1, 3.2), Vector3(-3.5, 0.55, 1.5), rust)
	_box("KioskCanopy", Vector3(5.8, 0.28, 3.7), Vector3(-3.5, 2.0, 1.5), faded_blue)
	_box("FallenDirectory", Vector3(0.22, 2.4, 3.2), Vector3(8, 1.15, -3), sign_mat)
	_box("DirectoryBase", Vector3(1.0, 0.25, 1.0), Vector3(8, 0.15, -3), dark_material())
	# Broken escalator silhouette: rails and steps, intentionally blocked as scenery.
	for side in [-1.0, 1.0]:
		_box("EscalatorRail", Vector3(0.24, 1.25, 10), Vector3(13.5 + side * 2.0, 1.0, 5), rust)
	for i in range(10):
		_box("EscalatorStep", Vector3(3.7, 0.16, 0.62), Vector3(13.5, 0.18 + i * 0.105, 1.0 + i * 0.82), faded_blue)

func dark_material() -> Material:
	return _material(Color("#252b2c"))

func _build_shops() -> void:
	var wall := _material(Color("#5a5a52"))
	var shutter := _material(Color("#30383b"), 0.55, 0.18)
	var counter := _material(Color("#665b4c"))
	for side in [-1.0, 1.0]:
		for i in range(3):
			var z := -15.0 + i * 14.0
			var x := side * 25.0
			_box("ClosedShopPartition", Vector3(9.0, 4.0, 0.55), Vector3(x, 2.0, z), wall)
			_box("ShopRollerShutter", Vector3(0.16, 3.0, 7.0), Vector3(x - side * 4.3, 1.8, z), shutter)
			_box("AbandonedCounter", Vector3(2.8, 1.15, 1.0), Vector3(x - side * 1.3, 0.58, z + 2.2), counter)
			_box("ShopSign", Vector3(6.2, 0.55, 0.22), Vector3(x - side * 1.4, 4.25, z), _material(Color("#8d7450")), false)

func _build_debris() -> void:
	var rubble := _material(Color("#5c5b55"))
	var paper := _material(Color("#b5a88c"))
	for i in range(34):
		var x := rng.randf_range(-27, 27)
		var z := rng.randf_range(-21, 21)
		if absf(x) < 11 and absf(z) < 8:
			continue
		var size := Vector3(rng.randf_range(0.2, 1.0), rng.randf_range(0.08, 0.35), rng.randf_range(0.2, 0.9))
		_box("ConcreteDebris", size, Vector3(x, size.y * 0.5, z), rubble if i % 3 else paper, false)

func _build_props() -> void:
	var colors := [
		_material(Color("#7b6a51")), _material(Color("#526c69")),
		_material(Color("#8a8270")), _material(Color("#42494c")),
		_material(Color("#92714f")), _material(Color("#65716b"))
	]
	for i in range(30):
		var x := rng.randf_range(-27.0, 27.0)
		var z := rng.randf_range(-20.0, 20.0)
		if absf(x) < 7.0 and absf(z) < 5.0:
			x += 10.0 if x >= 0.0 else -10.0
		var pos := Vector3(x, 0.0, z)
		var kind := i % 5
		match kind:
			0:
				_box("AbandonedCart", Vector3(1.1, 0.9, 0.7), pos + Vector3(0, 0.45, 0), colors[i % colors.size()])
			1:
				_cylinder("OldBarrel", 0.48, 1.15, pos + Vector3(0, 0.58, 0), colors[i % colors.size()])
			2:
				_box("ShopDisplay", Vector3(1.2, 1.35, 0.8), pos + Vector3(0, 0.68, 0), colors[i % colors.size()])
			3:
				_cylinder("LargePlanter", 0.7, 0.75, pos + Vector3(0, 0.38, 0), colors[i % colors.size()])
			4:
				_box("LostSuitcase", Vector3(0.85, 0.55, 0.48), pos + Vector3(0, 0.28, 0), colors[i % colors.size()])
		disguise_points.append(pos + Vector3(0, 0.5, 0))

func _build_overgrowth() -> void:
	var mold_dark := _material(Color("#293d32"), 0.98)
	var mold_mid := _material(Color("#405343"), 0.96)
	var vine_mat := _material(Color("#344b35"), 0.92)
	var vine_light := _material(Color("#536347"), 0.9)
	# Irregular damp patches on the floor and lower walls.
	for i in range(26):
		var x := rng.randf_range(-29.0, 29.0)
		var z := rng.randf_range(-21.0, 21.0)
		var sx := rng.randf_range(0.45, 2.4)
		var sz := rng.randf_range(0.35, 1.8)
		var patch := _box("MoldPatchFloor", Vector3(sx, 0.018, sz), Vector3(x, 0.018, z), mold_dark if i % 2 == 0 else mold_mid, false)
		patch.rotation.y = rng.randf_range(-0.6, 0.6)
	# Vertical mold stains along the outer walls.
	for side in [-1.0, 1.0]:
		for i in range(9):
			var z := -20.0 + i * 5.0
			var stain := _box("MoldStainWall", Vector3(0.025, rng.randf_range(0.8, 2.8), rng.randf_range(0.5, 2.0)), Vector3(side * 31.42, rng.randf_range(1.2, 3.0), z), mold_mid, false)
			stain.rotation.x = rng.randf_range(-0.12, 0.12)
	# Hanging roots and vines: short linked cylinders keep the mesh inexpensive.
	for i in range(18):
		var start := Vector3(rng.randf_range(-29.0, 29.0), 8.9, rng.randf_range(-21.0, 21.0))
		var length := rng.randf_range(1.1, 3.8)
		var sway := Vector3(rng.randf_range(-1.2, 1.2), -length, rng.randf_range(-1.2, 1.2))
		_add_vine_segment(start, start + sway * 0.45, vine_mat, 0.055)
		_add_vine_segment(start + sway * 0.45, start + sway, vine_light if i % 3 == 0 else vine_mat, 0.04)

func _add_vine_segment(a: Vector3, b: Vector3, mat: Material, radius: float) -> void:
	var delta := b - a
	var length := delta.length()
	if length < 0.05:
		return
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.72
	mesh.bottom_radius = radius
	mesh.height = length
	var visual := MeshInstance3D.new()
	visual.name = "HangingVine"
	visual.mesh = mesh
	visual.material_override = mat
	visual.position = (a + b) * 0.5
	visual.look_at(b, Vector3.UP)
	visual.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	add_child(visual)

func _build_atmosphere_details() -> void:
	var broken_glass := _material(Color(0.42, 0.55, 0.57, 0.42), 0.12, 0.28)
	var dirty_metal := _material(Color("#303638"), 0.82, 0.32)
	# Fallen ceiling frames and shards suggest long-term abandonment.
	for i in range(12):
		var x := rng.randf_range(-27.0, 27.0)
		var z := rng.randf_range(-21.0, 21.0)
		if absf(x) < 8.0 and absf(z) < 6.0:
			continue
		var shard := _box("BrokenGlassShard", Vector3(rng.randf_range(0.25, 0.8), 0.025, rng.randf_range(0.18, 0.55)), Vector3(x, 0.035, z), broken_glass, false)
		shard.rotation.y = rng.randf_range(-PI, PI)
	for i in range(5):
		var beam := _box("FallenCeilingFrame", Vector3(rng.randf_range(2.5, 5.5), 0.12, 0.16), Vector3(rng.randf_range(-25.0, 25.0), rng.randf_range(0.5, 2.2), rng.randf_range(-20.0, 20.0)), dirty_metal, false)
		beam.rotation.z = rng.randf_range(-0.7, 0.7)
