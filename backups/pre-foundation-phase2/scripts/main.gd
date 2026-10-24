extends Node

const ShopWorldScript := preload("res://scripts/shop_world.gd")

enum Phase { BRIEF, WORK, RESULT }

const TOOLS := [
	{"id": "hand", "label": "Hand"},
	{"id": "drain_pan", "label": "Pan"},
	{"id": "socket", "label": "Socket"},
	{"id": "filter_wrench", "label": "Filter"},
	{"id": "oil_jug", "label": "Oil"},
]

var world: Node3D
var hud: Node

var phase: Phase = Phase.BRIEF
var job: Dictionary = {}
var prices: Dictionary = {}
var cash_cents: int = 75000
var selected_tool: String = "hand"
var hood_open: bool = false
var fill_cap_open: bool = false
var pan_placed: bool = false
var drain_plug_on: bool = true
var filter_on: bool = true
var filter_is_new: bool = false
var oil_drained: bool = false
var oil_draining: bool = false
var oil_quarts: float = 0.0
var last_message: String = ""


func _ready() -> void:
	_load_data()
	world = ShopWorldScript.new()
	$WorldRoot.add_child(world)
	world.part_tapped.connect(_on_part_tapped)
	hud = $HUD
	hud.setup(self)
	_refresh()
	if OS.get_environment("MYSHOP_CAPTURE") != "":
		accept_job()
		call_deferred("_capture_views")


func money(cents: int) -> String:
	return "$%.2f" % (cents / 100.0)


func accept_job() -> void:
	if phase != Phase.BRIEF:
		return
	phase = Phase.WORK
	last_message = "Place the drain pan under the car, then drain the oil."
	_refresh()


func select_tool(tool_id: String) -> void:
	selected_tool = tool_id
	last_message = "Selected %s." % _tool_label(tool_id)
	_refresh()


func set_view(view_name: String) -> void:
	world.set_view(view_name)
	_refresh()


func complete_job() -> void:
	if phase != Phase.WORK or not _can_complete():
		last_message = "The repair is not finished yet."
		_refresh()
		return
	var job_prices: Dictionary = prices.get("jobs", {}).get(job.get("id", ""), {})
	var charge: int = int(job_prices.get("customer_charge_cents", 5500))
	var parts_cost: int = int(job_prices.get("parts_cost_cents", 2200))
	var consumables: int = int(job_prices.get("consumables_cost_cents", 150))
	var profit: int = charge - parts_cost - consumables
	cash_cents += profit
	phase = Phase.RESULT
	last_message = "Job complete. Net %s after parts and supplies." % money(profit)
	_refresh()


func restart_job() -> void:
	hood_open = false
	fill_cap_open = false
	pan_placed = false
	drain_plug_on = true
	filter_on = true
	filter_is_new = false
	oil_drained = false
	oil_draining = false
	oil_quarts = 0.0
	selected_tool = "hand"
	phase = Phase.BRIEF
	last_message = ""
	world.set_hood_open(false)
	world.set_oil_draining(false)
	world.set_part_visible("drain_plug", true)
	world.set_part_visible("oil_filter", true)
	world.set_part_visible("fill_cap", true)
	world.set_view("bay")
	_refresh()


func hint_text() -> String:
	if last_message != "":
		return last_message
	if phase == Phase.BRIEF:
		return String(job.get("guided_intro", "Read the work order, then start the job."))
	if not pan_placed:
		return "Guided: put the drain pan under the engine before you open anything that can spill."
	if not oil_drained and drain_plug_on:
		return "Guided: use the socket on the drain plug, then let the old oil empty."
	if oil_draining:
		return "Old oil is draining. Wait for it to finish."
	if not drain_plug_on:
		return "Guided: put the drain plug back in with the socket before you refill."
	if not filter_is_new:
		return "Guided: remove the old filter with the filter wrench, then tap again to install the new one."
	if not hood_open:
		return "Guided: switch to the engine view and open the hood."
	if not fill_cap_open and oil_quarts < float(job.get("oil_quarts_needed", 5)):
		return "Guided: open the oil fill cap, then pour with the oil jug."
	if oil_quarts < float(job.get("oil_quarts_needed", 5)):
		return "Guided: keep pouring until the engine has %s quarts. This is a game quantity, not a verified OEM spec." % str(job.get("oil_quarts_needed", 5))
	if fill_cap_open:
		return "Guided: close the fill cap, then verify the job."
	return "Guided: tap Complete job when you are satisfied the oil change is done."


func _can_complete() -> bool:
	return (
		oil_drained
		and drain_plug_on
		and filter_on
		and filter_is_new
		and oil_quarts >= float(job.get("oil_quarts_needed", 5))
		and not fill_cap_open
	)


func _on_part_tapped(part_id: String) -> void:
	if phase != Phase.WORK or oil_draining:
		return
	world.set_highlight(part_id, true)
	match part_id:
		"drain_pan_spot":
			_handle_pan()
		"drain_plug":
			_handle_drain_plug()
		"oil_filter":
			_handle_filter()
		"hood":
			_handle_hood()
		"fill_cap":
			_handle_fill_cap()
		"dipstick":
			_handle_dipstick()
		_:
			last_message = "That part is not used on this job."
	_refresh()


func _handle_pan() -> void:
	if selected_tool != "drain_pan" and not pan_placed:
		last_message = "Select the drain pan first, then tap the spot under the engine."
		return
	pan_placed = true
	last_message = "Drain pan is in place."


func _handle_drain_plug() -> void:
	if not pan_placed:
		last_message = "Put the drain pan under the car first. Old oil will spill."
		return
	if selected_tool != "socket":
		last_message = "The drain plug needs the socket, not the %s." % _tool_label(selected_tool)
		return
	if drain_plug_on:
		drain_plug_on = false
		world.set_part_visible("drain_plug", false)
		oil_draining = true
		world.set_oil_draining(true)
		last_message = "Drain plug out. Old oil is draining."
		get_tree().create_timer(1.6).timeout.connect(_finish_drain)
	else:
		drain_plug_on = true
		world.set_part_visible("drain_plug", true)
		last_message = "Drain plug reinstalled. Snug only — no invented torque spec in this prototype."


func _finish_drain() -> void:
	oil_draining = false
	oil_drained = true
	oil_quarts = 0.0
	world.set_oil_draining(false)
	last_message = "Old oil is out. Reinstall the drain plug, then replace the filter."
	_refresh()


func _handle_filter() -> void:
	if not pan_placed:
		last_message = "Place the drain pan first. Filter changes can spill oil."
		return
	if selected_tool != "filter_wrench" and selected_tool != "hand":
		last_message = "Use the filter wrench or your hand on the oil filter."
		return
	if filter_on:
		if selected_tool != "filter_wrench":
			last_message = "The old filter is on tight. Use the filter wrench."
			return
		filter_on = false
		filter_is_new = false
		world.set_part_visible("oil_filter", false)
		last_message = "Old filter removed. Tap the filter area again to install the new one."
	else:
		filter_on = true
		filter_is_new = true
		world.set_part_visible("oil_filter", true)
		last_message = "New filter installed by hand. Do not overtighten."


func _handle_hood() -> void:
	if selected_tool != "hand":
		last_message = "Open the hood with your hand."
		return
	hood_open = not hood_open
	world.set_hood_open(hood_open)
	last_message = "Hood open." if hood_open else "Hood closed."


func _handle_fill_cap() -> void:
	if not hood_open:
		last_message = "Open the hood first."
		return
	if selected_tool == "oil_jug":
		if not fill_cap_open:
			last_message = "Open the fill cap with your hand before pouring."
			return
		if not oil_drained or not drain_plug_on or not filter_is_new:
			last_message = "Finish the drain, plug, and new filter before adding oil."
			return
		var needed := float(job.get("oil_quarts_needed", 5))
		if oil_quarts >= needed:
			last_message = "The engine already has the game fill quantity."
			return
		oil_quarts += 1.0
		last_message = "Poured 1 quart. Level %s / %s quarts." % [str(oil_quarts), str(needed)]
		return
	if selected_tool != "hand":
		last_message = "Use your hand to open or close the fill cap."
		return
	fill_cap_open = not fill_cap_open
	world.set_part_visible("fill_cap", not fill_cap_open)
	last_message = "Fill cap open." if fill_cap_open else "Fill cap closed."


func _handle_dipstick() -> void:
	if not hood_open:
		last_message = "Open the hood to reach the dipstick."
		return
	if selected_tool != "hand":
		last_message = "Check the dipstick with your hand."
		return
	var needed := float(job.get("oil_quarts_needed", 5))
	if not oil_drained:
		last_message = "Dipstick is dark and dirty. This engine still has old oil."
	elif oil_quarts <= 0:
		last_message = "Dipstick is dry. The engine has no oil."
	elif oil_quarts < needed:
		last_message = "Dipstick is low. Add more oil."
	else:
		last_message = "Dipstick looks full enough for this game fill. Check for leaks next."


func _tool_label(tool_id: String) -> String:
	for tool in TOOLS:
		if tool["id"] == tool_id:
			return String(tool["label"])
	return tool_id


func _load_data() -> void:
	job = _read_json("res://data/jobs/oil_change.json")
	var economy := _read_json("res://data/economy.json")
	prices = economy
	cash_cents = int(economy.get("starting_cash_cents", 75000))


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Missing data file: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _refresh() -> void:
	if hud:
		hud.refresh()


func _capture_views() -> void:
	var dir := "user://captures"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	await get_tree().process_frame
	await get_tree().process_frame
	for view_name in ["bay", "under", "engine"]:
		set_view(view_name)
		await get_tree().create_timer(0.5).timeout
		var image := get_viewport().get_texture().get_image()
		var path := "%s/%s.png" % [dir, view_name]
		image.save_png(path)
		print("CAPTURED ", ProjectSettings.globalize_path(path))
	quit_request()


func quit_request() -> void:
	get_tree().quit()
