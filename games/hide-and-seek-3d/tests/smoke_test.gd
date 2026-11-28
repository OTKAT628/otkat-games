extends SceneTree

func _initialize() -> void:
	call_deferred("_run_smoke_test")

func _run_smoke_test() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("Main scene could not be loaded.")
		return

	var game = packed.instantiate()
	root.add_child(game)
	await process_frame

	if game.player == null or game.hunter == null or game.mall == null:
		_fail("Game did not create player, hunter and mall.")
		return
	if game.mall.disguise_points.size() < 20:
		_fail("Mall did not create enough disguise points.")
		return

	game.call("_start_round")
	await process_frame
	if not game.round_active:
		_fail("Round did not start.")
		return
	if game.weapon_runtime.ammo_in_magazine <= 0 or not game.inventory.owns_weapon("ap_scout"):
		_fail("Starter weapon or ammunition was not initialized.")
		return

	game.player.global_position = game.mall.disguise_points[0] + Vector3(0, 0, 0.8)
	game.call("_toggle_disguise")
	if not game.player.disguised or game.player.collision_layer != 0 or game.player.weapon_mount.visible:
		_fail("Disguise did not hide the player, weapon and player collision.")
		return
	game.call("_leave_disguise")
	if game.player.disguised or game.player.collision_layer == 0 or not game.player.weapon_mount.visible:
		_fail("Leaving disguise did not restore the player and weapon.")
		return

	game.player._set_crouch_pose(true)
	if not is_equal_approx(game.player.body_capsule.height, 1.05):
		_fail("Crouch did not change the player collision capsule.")
		return
	game.player._set_crouch_pose(false)
	game.player.toggle_camera_mode()
	if not game.player.third_person:
		_fail("Third-person camera mode did not activate.")
		return
	game.player.toggle_camera_mode()
	if game.player.third_person or game.player.weapon_mount.visible == false:
		_fail("First-person camera mode did not restore the weapon view.")
		return

	var initial_hunter_health := game.hunter.health
	game.call("_on_weapon_hit", game.hunter, "ap_scout")
	if game.hunter.health >= initial_hunter_health:
		_fail("Weapon hit did not damage the hunter.")
		return

	game.round_phase = "hunt"
	game.call("_use_ability", "freeze")
	if game.hunter.frozen_time <= 0.0:
		_fail("Freeze ability did not affect the hunter.")
		return
	game.call("_use_ability", "bag")
	if game.hunter.bagged_time <= 0.0:
		_fail("Bag ability did not slow the hunter.")
		return
	game.call("_use_ability", "decoy")
	if game.hunter.lure_time <= 0.0:
		_fail("Decoy ability did not lure the hunter.")
		return
	if game.get_node_or_null("DecoyEcho") == null:
		_fail("Decoy ability did not create a visible decoy.")
		return

	var previous_wins := game.total_wins
	game.call("_finish", true)
	if game.total_wins != previous_wins + 1 or game.inventory.credits < 100:
		_fail("Victory reward and profile progression were not saved.")
		return

	print("OTKAT Hide & Seek smoke test passed.")
	quit(0)

func _fail(message: String) -> void:
	push_error("OTKAT Hide & Seek smoke test failed: " + message)
	quit(1)
