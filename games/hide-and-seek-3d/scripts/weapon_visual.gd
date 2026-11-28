extends Node3D
class_name OtkatWeaponVisual
## Procedural, modular first-person weapon presentation.
## Geometry is a detailed greybox pending authored production meshes.

const SKIN_FINISHES := {
	"field": {"base":"#4b5145","secondary":"#262c29","metal":"#454b4d","roughness":0.86,"accent":"#77765d"},
	"urban": {"base":"#555b60","secondary":"#252a30","metal":"#9aa0a1","roughness":0.72,"accent":"#78858b"},
	"obsidian": {"base":"#171b22","secondary":"#080b10","metal":"#424b59","roughness":0.22,"accent":"#c6a45b"},
	"graphite": {"base":"#353b42","secondary":"#171b20","metal":"#6e777e","roughness":0.48,"accent":"#b2b9bd"},
	"sand": {"base":"#8c7958","secondary":"#403b30","metal":"#6d6556","roughness":0.9,"accent":"#c0a97b"},
	"chrome": {"base":"#aab3b8","secondary":"#343c43","metal":"#d8e0e2","roughness":0.16,"accent":"#e5bd68"},
	"neon": {"base":"#172b36","secondary":"#10151e","metal":"#47717d","roughness":0.3,"accent":"#39d5d0"},
	"ember": {"base":"#48252a","secondary":"#21191d","metal":"#8d5145","roughness":0.52,"accent":"#f28b52"},
	"bone": {"base":"#c1b69c","secondary":"#554d42","metal":"#8c806d","roughness":0.82,"accent":"#8a514b"},
	"default": {"base":"#41494b","secondary":"#20272a","metal":"#687174","roughness":0.68,"accent":"#d1ad61"}
}

var finish: Dictionary = SKIN_FINISHES["default"]
var root: Node3D

func build(weapon_type: String, skin_id: String = "") -> void:
	for child in get_children():
		child.queue_free()
	finish = _finish_for_skin(skin_id)
	root = Node3D.new()
	root.name = "WeaponAssembly"
	add_child(root)
	match weapon_type:
		"shotgun", "pump_shotgun":
			_build_shotgun()
		"sidearm", "service_sidearm":
			_build_sidearm()
		"plasma_rifle", "energy_sidearm", "toy_blaster":
			_build_energy_rifle()
		"launcher", "stun_emitter", "arcane_focus", "sonic_relic":
			_build_special_device()
		"energy_blade":
			_build_energy_blade()
		_:
			_build_sidearm()

func _finish_for_skin(skin_id: String) -> Dictionary:
	var id := skin_id.to_lower()
	for key in SKIN_FINISHES.keys():
		if id.contains(key):
			return SKIN_FINISHES[key]
	if id.contains("rust") or id.contains("wasteland"):
		return {"base":"#70503d","secondary":"#302a27","metal":"#554e46","roughness":0.94,"accent":"#b18a57"}
	if id.contains("gold") or id.contains("crown"):
		return {"base":"#806334","secondary":"#28231c","metal":"#c49a48","roughness":0.3,"accent":"#f1d98b"}
	if id.contains("sakura") or id.contains("spirit"):
		return {"base":"#5d354e","secondary":"#29202c","metal":"#a77b9b","roughness":0.4,"accent":"#e8a9c7"}
	if id.contains("circuit") or id.contains("singularity"):
		return {"base":"#1b3b48","secondary":"#111a27","metal":"#4c9ca8","roughness":0.26,"accent":"#55e6d7"}
	return SKIN_FINISHES["default"]

func _mat(color_hex: String, roughness: float, metallic: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color_hex)
	m.roughness = roughness
	m.metallic = metallic
	return m

func _part(part_name: String, size: Vector3, pos: Vector3, material: Material, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.name = part_name
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	node.rotation = rotation
	root.add_child(node)
	return node

func _cylinder(part_name: String, radius: float, length: float, pos: Vector3, material: Material, along_z: bool = false) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.96
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.radial_segments = 16
	var node := MeshInstance3D.new()
	node.name = part_name
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	if along_z:
		node.rotation.x = PI * 0.5
	root.add_child(node)
	return node

func _build_shotgun() -> void:
	var body := _mat(str(finish.base), float(finish.roughness), 0.42)
	var polymer := _mat(str(finish.secondary), 0.82, 0.05)
	var metal := _mat(str(finish.metal), 0.34, 0.78)
	var accent := _mat(str(finish.accent), 0.42, 0.38)
	_part("Receiver", Vector3(0.22, 0.25, 0.64), Vector3(0, 0, -0.05), body)
	_part("UpperReceiverRail", Vector3(0.12, 0.045, 0.58), Vector3(0, 0.15, -0.08), metal)
	_cylinder("Barrel", 0.052, 0.72, Vector3(0, 0.015, -0.68), metal, true)
	_cylinder("Muzzle", 0.067, 0.11, Vector3(0, 0.015, -1.06), accent, true)
	_part("PumpForegrip", Vector3(0.19, 0.16, 0.28), Vector3(0, -0.12, -0.54), polymer)
	_part("Stock", Vector3(0.17, 0.19, 0.43), Vector3(0, -0.01, 0.47), polymer, Vector3(0.16, 0, 0))
	_part("ButtPad", Vector3(0.19, 0.23, 0.07), Vector3(0, -0.01, 0.72), metal)
	_part("PistolGrip", Vector3(0.13, 0.27, 0.16), Vector3(0, -0.23, 0.12), polymer, Vector3(-0.2, 0, 0))
	_part("TriggerGuard", Vector3(0.13, 0.035, 0.17), Vector3(0, -0.17, -0.02), accent)
	_part("FrontSight", Vector3(0.035, 0.11, 0.04), Vector3(0, 0.12, -0.96), accent)
	_part("RearSight", Vector3(0.11, 0.07, 0.055), Vector3(0, 0.17, -0.15), metal)
	for side in [-1.0, 1.0]:
		_part("ReceiverPin", Vector3(0.025, 0.025, 0.025), Vector3(side * 0.115, 0.035, 0.06), accent)
		_part("StockScrew", Vector3(0.025, 0.025, 0.025), Vector3(side * 0.09, -0.02, 0.46), metal)
		_part("HandguardSlot", Vector3(0.012, 0.025, 0.12), Vector3(side * 0.098, -0.11, -0.53), metal)

func _build_sidearm() -> void:
	var body := _mat(str(finish.base), float(finish.roughness), 0.48)
	var grip := _mat(str(finish.secondary), 0.86, 0.02)
	var metal := _mat(str(finish.metal), 0.28, 0.82)
	var accent := _mat(str(finish.accent), 0.38, 0.35)
	_part("Slide", Vector3(0.16, 0.16, 0.48), Vector3(0, 0.055, -0.13), body)
	_part("SlideTop", Vector3(0.11, 0.025, 0.4), Vector3(0, 0.145, -0.13), metal)
	_part("Frame", Vector3(0.15, 0.1, 0.43), Vector3(0, -0.045, -0.1), metal)
	_part("Grip", Vector3(0.13, 0.29, 0.18), Vector3(0, -0.21, 0.14), grip, Vector3(-0.18, 0, 0))
	_part("MagazineBase", Vector3(0.12, 0.035, 0.14), Vector3(0, -0.34, 0.14), accent)
	_cylinder("Barrel", 0.035, 0.12, Vector3(0, 0.025, -0.42), metal, true)
	_part("FrontSight", Vector3(0.025, 0.06, 0.025), Vector3(0, 0.16, -0.31), accent)
	_part("RearSight", Vector3(0.1, 0.045, 0.035), Vector3(0, 0.16, 0.06), metal)
	_part("Trigger", Vector3(0.025, 0.1, 0.055), Vector3(0, -0.12, 0.015), accent)
	for i in range(5):
		_part("SlideSerration", Vector3(0.012, 0.07, 0.018), Vector3(0.084, 0.055, -0.28 + i * 0.045), metal)

func _build_energy_rifle() -> void:
	var body := _mat(str(finish.base), float(finish.roughness), 0.52)
	var dark := _mat(str(finish.secondary), 0.42, 0.35)
	var metal := _mat(str(finish.metal), 0.28, 0.76)
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(str(finish.accent))
	glow.emission_enabled = true
	glow.emission = Color(str(finish.accent))
	glow.emission_energy_multiplier = 1.3
	_part("MainHousing", Vector3(0.28, 0.31, 0.72), Vector3(0, 0, -0.04), body)
	_part("TopRail", Vector3(0.13, 0.045, 0.67), Vector3(0, 0.19, -0.08), metal)
	_part("EnergyEmitter", Vector3(0.14, 0.14, 0.26), Vector3(0, 0.01, -0.53), dark)
	_cylinder("EmitterCore", 0.07, 0.2, Vector3(0, 0.015, -0.72), glow, true)
	_part("PowerCell", Vector3(0.16, 0.28, 0.22), Vector3(0, -0.23, -0.05), dark)
	_part("CellWindow", Vector3(0.09, 0.15, 0.025), Vector3(0, -0.22, -0.17), glow)
	_part("Grip", Vector3(0.15, 0.28, 0.18), Vector3(0, -0.22, 0.25), dark)
	_part("RearStock", Vector3(0.18, 0.16, 0.34), Vector3(0, -0.015, 0.52), body)
	for side in [-1.0, 1.0]:
		_part("CoolingVent", Vector3(0.025, 0.12, 0.3), Vector3(side * 0.15, 0.015, -0.05), metal)
		_part("EnergyStrip", Vector3(0.018, 0.035, 0.42), Vector3(side * 0.16, 0.12, -0.08), glow)

func _build_special_device() -> void:
	var body := _mat(str(finish.base), float(finish.roughness), 0.38)
	var dark := _mat(str(finish.secondary), 0.72, 0.12)
	var metal := _mat(str(finish.metal), 0.32, 0.72)
	var accent := _mat(str(finish.accent), 0.3, 0.44)
	_part("DeviceHousing", Vector3(0.3, 0.36, 0.56), Vector3(0, 0, -0.04), body)
	_cylinder("FrontCoil", 0.13, 0.12, Vector3(0, 0, -0.39), metal, true)
	_cylinder("EmitterRing", 0.105, 0.04, Vector3(0, 0, -0.47), accent, true)
	_part("PowerCore", Vector3(0.12, 0.2, 0.2), Vector3(0, 0.02, -0.05), accent)
	_part("Grip", Vector3(0.17, 0.29, 0.2), Vector3(0, -0.25, 0.15), dark)
	_part("SafetyGuard", Vector3(0.28, 0.045, 0.055), Vector3(0, 0.21, 0.02), metal)
	for side in [-1.0, 1.0]:
		_cylinder("SideCanister", 0.055, 0.27, Vector3(side * 0.19, 0.0, -0.02), metal)
		_part("WarningMark", Vector3(0.018, 0.09, 0.13), Vector3(side * 0.155, 0.04, -0.04), accent)

func _build_energy_blade() -> void:
	var hilt := _mat(str(finish.secondary), 0.32, 0.8)
	var accent := StandardMaterial3D.new()
	accent.albedo_color = Color(str(finish.accent))
	accent.emission_enabled = true
	accent.emission = Color(str(finish.accent))
	accent.emission_energy_multiplier = 2.0
	_part("Hilt", Vector3(0.11, 0.13, 0.32), Vector3(0, 0, 0.24), hilt)
	_part("Guard", Vector3(0.38, 0.07, 0.1), Vector3(0, 0, 0.05), hilt)
	_part("BladeCore", Vector3(0.065, 0.075, 0.95), Vector3(0, 0, -0.58), accent)
	_part("BladeEdge", Vector3(0.025, 0.095, 0.9), Vector3(0.045, 0, -0.58), accent)
