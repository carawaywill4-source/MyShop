extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn")
	if packed == null:
		push_error("Missing main scene")
		quit(1)
		return
	var main: Node = packed.instantiate()
	root.add_child(main)
	var failed := 0
	failed += _expect(main.cash_cents == 75000, "starting cash is 75000")
	failed += _expect(String(main.job.get("vehicle_label", "")) == "2016 Harbor Commute", "vehicle label")
	var prices: Dictionary = main.prices.get("jobs", {}).get("oil_change_commuter", {})
	failed += _expect(int(prices.get("customer_charge_cents", 0)) == 5500, "job charge 5500")
	failed += _expect(int(prices.get("parts_cost_cents", 0)) + int(prices.get("consumables_cost_cents", 0)) == 2350, "parts+supplies 2350")
	var world: Node = main.world
	failed += _expect(world.parts.has("hood"), "hood interactable")
	failed += _expect(world.parts.has("drain_plug"), "drain plug interactable")
	failed += _expect(world.parts.has("oil_filter"), "oil filter interactable")
	failed += _expect(world.parts.has("fill_cap"), "fill cap interactable")
	failed += _expect(world.parts.has("drain_pan_spot"), "drain pan interactable")
	failed += _expect(main.world.vehicle.has_interior(), "job car has a cabin")
	failed += _expect(main.world.vehicle.hood_pivot != null, "hood uses a hinge pivot")
	main.scan_obd()
	failed += _expect(main.last_message.contains("no stored codes"), "healthy car has no OBD codes")
	main.set_fault("misfire_cyl1")
	main.scan_obd()
	failed += _expect(main.last_message.contains("P0301") and main.last_message.contains("coil"), "scanner reports the coil misfire")
	main.clear_codes()
	failed += _expect(main.has_fault("misfire_cyl1") and main.last_message.contains("does not fix"), "clearing a code leaves the fault")
	main.scan_obd()
	failed += _expect(main.last_message.contains("P0301"), "code returns while the coil is still failed")
	failed += _expect(main.repair_fault("misfire_cyl1"), "replacing the coil repairs the fault")
	main.scan_obd()
	failed += _expect(main.last_message.contains("no stored codes") and not main.has_fault("misfire_cyl1"), "lamp state clears only after the repair")
	main.set_view("cabin")
	failed += _expect(not main.last_message.contains("no separate cabin"), "cabin camera accepted")
	failed += _expect(main.world.vehicle.get_node_or_null("Interior/DriverEye") != null, "driver eye marker")
	failed += _expect(main.world.vehicle.get_node_or_null("Interior/Cluster") != null, "instrument cluster")
	failed += _expect(main.world.parts.has("obd_port"), "obd port")
	failed += _expect(main.world.parts.has("ignition_coil"), "ignition coil")
	var harbor_door: bool = main.world.vehicle.set_panel_open("door_fl", true, true)
	var harbor_pivot := main.world.vehicle.get_node_or_null("Body/door_fl") as Node3D
	failed += _expect(harbor_door and harbor_pivot != null and absf(harbor_pivot.rotation.y) > 0.4, "Harbor driver door hinges open")
	main.world.set_panel_open("door_fl", false, true)
	main.world.load_vehicle(1)
	var door_open: bool = main.world.vehicle.set_panel_open("door_fl", true, true)
	var door_pivot := main.world.vehicle.get_node_or_null("Body/door_fl") as Node3D
	failed += _expect(door_open and door_pivot != null and absf(door_pivot.rotation.y) > 0.4, "Kessler front door hinges open")
	main.world.load_vehicle(0)
	main.accept_job()
	main.select_tool("hand")
	main._on_part_tapped("drain_plug")
	failed += _expect(main.last_message.contains("drain pan") or main.last_message.contains("Pan"), "wrong-tool or missing-pan feedback")
	main.select_tool("drain_pan")
	main._on_part_tapped("drain_pan_spot")
	main.select_tool("socket")
	main._on_part_tapped("drain_plug")
	failed += _expect(main.oil_draining or not main.drain_plug_on, "drain started")
	main._finish_drain()
	main.select_tool("socket")
	main._on_part_tapped("drain_plug")
	main.select_tool("filter_wrench")
	main._on_part_tapped("oil_filter")
	main.select_tool("hand")
	main._on_part_tapped("oil_filter")
	main._on_part_tapped("hood")
	main._on_part_tapped("fill_cap")
	main.select_tool("oil_jug")
	for _i in 5:
		main._on_part_tapped("fill_cap")
	main.select_tool("hand")
	main._on_part_tapped("fill_cap")
	failed += _expect(main._can_complete(), "job can complete")
	main.complete_job()
	failed += _expect(main.phase == main.Phase.RESULT, "result screen")
	failed += _expect(main.cash_cents == 78150, "cash after profit 3150")
	if failed == 0:
		print("SMOKE TEST PASSED")
		quit(0)
	else:
		print("SMOKE TEST FAILED %s checks" % failed)
		quit(1)


func _expect(ok: bool, label: String) -> int:
	if ok:
		print("OK  ", label)
		return 0
	print("FAIL", label)
	return 1
