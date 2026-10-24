extends CanvasLayer

var game: Node

var _cash: Label
var _job: Label
var _hint: Label
var _complete: Button
var _overlay: ColorRect
var _overlay_title: Label
var _overlay_body: RichTextLabel
var _overlay_button: Button
var _tool_buttons: Dictionary = {}


func setup(main: Node) -> void:
	game = main
	_build()
	refresh()


func refresh() -> void:
	if game == null or _cash == null:
		return
	_cash.text = game.money(game.cash_cents)
	_job.text = String(game.job.get("title", "Oil change"))
	_hint.text = game.hint_text()
	_complete.visible = game.phase == game.Phase.WORK
	_complete.disabled = not game._can_complete()
	for tool_id in _tool_buttons:
		var button: Button = _tool_buttons[tool_id]
		button.button_pressed = game.selected_tool == tool_id
	_update_overlay()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 16
	top.offset_right = -16
	top.offset_top = 10
	top.offset_bottom = 54
	top.add_theme_constant_override("separation", 16)
	root.add_child(top)

	var brand := Label.new()
	brand.text = "MyShop"
	brand.add_theme_font_size_override("font_size", 22)
	top.add_child(brand)
	_job = Label.new()
	_job.add_theme_font_size_override("font_size", 16)
	_job.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_job)
	_cash = Label.new()
	_cash.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_cash.add_theme_font_size_override("font_size", 20)
	top.add_child(_cash)

	var views := HBoxContainer.new()
	views.set_anchors_preset(Control.PRESET_TOP_WIDE)
	views.offset_left = 16
	views.offset_right = -16
	views.offset_top = 56
	views.offset_bottom = 100
	views.add_theme_constant_override("separation", 8)
	root.add_child(views)
	_add_view_button(views, "Bay", "bay")
	_add_view_button(views, "Under car", "under")
	_add_view_button(views, "Engine", "engine")

	var hint_panel := PanelContainer.new()
	hint_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint_panel.offset_left = 16
	hint_panel.offset_right = -16
	hint_panel.offset_top = -132
	hint_panel.offset_bottom = -78
	root.add_child(hint_panel)
	_hint = Label.new()
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_font_size_override("font_size", 15)
	hint_panel.add_child(_hint)

	var tools := HBoxContainer.new()
	tools.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	tools.offset_left = 16
	tools.offset_right = -16
	tools.offset_top = -70
	tools.offset_bottom = -12
	tools.add_theme_constant_override("separation", 8)
	root.add_child(tools)
	for tool in game.TOOLS:
		var button := Button.new()
		button.text = String(tool["label"])
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(92, 52)
		button.pressed.connect(game.select_tool.bind(String(tool["id"])))
		tools.add_child(button)
		_tool_buttons[String(tool["id"])] = button

	_complete = Button.new()
	_complete.text = "Complete job"
	_complete.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_complete.offset_left = -180
	_complete.offset_top = 56
	_complete.offset_right = -16
	_complete.offset_bottom = 100
	_complete.pressed.connect(game.complete_job)
	root.add_child(_complete)

	_overlay = ColorRect.new()
	_overlay.color = Color(0.05, 0.06, 0.08, 0.82)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(_overlay)
	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -260
	card.offset_top = -140
	card.offset_right = 260
	card.offset_bottom = 150
	_overlay.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	_overlay_title = Label.new()
	_overlay_title.add_theme_font_size_override("font_size", 22)
	box.add_child(_overlay_title)
	_overlay_body = RichTextLabel.new()
	_overlay_body.bbcode_enabled = true
	_overlay_body.fit_content = true
	_overlay_body.scroll_active = false
	_overlay_body.custom_minimum_size = Vector2(500, 140)
	box.add_child(_overlay_body)
	_overlay_button = Button.new()
	_overlay_button.custom_minimum_size = Vector2(0, 48)
	_overlay_button.pressed.connect(_on_overlay_pressed)
	box.add_child(_overlay_button)


func _add_view_button(parent: Control, label: String, view_name: String) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(110, 40)
	button.pressed.connect(game.set_view.bind(view_name))
	parent.add_child(button)


func _update_overlay() -> void:
	var job_prices: Dictionary = game.prices.get("jobs", {}).get(game.job.get("id", ""), {})
	if game.phase == game.Phase.BRIEF:
		_overlay.visible = true
		_overlay_title.text = "Work order"
		_overlay_body.text = "[b]%s[/b]\n%s\n\n%s\n\nCustomer charge: %s\nParts and supplies: %s\nThese prices are illustrative game values." % [
			String(game.job.get("title", "Job")),
			String(game.job.get("vehicle_label", "Vehicle")),
			String(game.job.get("complaint", "")),
			game.money(int(job_prices.get("customer_charge_cents", 0))),
			game.money(int(job_prices.get("parts_cost_cents", 0)) + int(job_prices.get("consumables_cost_cents", 0))),
		]
		_overlay_button.text = "Start job"
	elif game.phase == game.Phase.RESULT:
		_overlay.visible = true
		var charge := int(job_prices.get("customer_charge_cents", 0))
		var parts_cost := int(job_prices.get("parts_cost_cents", 0))
		var consumables := int(job_prices.get("consumables_cost_cents", 0))
		var profit := charge - parts_cost - consumables
		_overlay_title.text = "Job complete"
		_overlay_body.text = "Customer paid %s\nParts %s\nSupplies %s\n[b]Shop kept %s[/b]\n\nCash on hand: %s\n\nA $55 oil change is not $55 of free money. This screen exists so the later economy can stay honest." % [
			game.money(charge),
			game.money(parts_cost),
			game.money(consumables),
			game.money(profit),
			game.money(game.cash_cents),
		]
		_overlay_button.text = "Run the job again"
	else:
		_overlay.visible = false


func _on_overlay_pressed() -> void:
	if game.phase == game.Phase.BRIEF:
		game.accept_job()
	elif game.phase == game.Phase.RESULT:
		game.restart_job()
