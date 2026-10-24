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
var _next_car: Button
var _tool_buttons: Dictionary = {}
var _theme: Theme


func setup(main: Node) -> void:
	game = main
	_theme = _make_theme()
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


func _make_theme() -> Theme:
	var theme := Theme.new()
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.10, 0.11, 0.13, 0.92)
	panel.set_corner_radius_all(8)
	panel.content_margin_left = 12
	panel.content_margin_right = 12
	panel.content_margin_top = 8
	panel.content_margin_bottom = 8
	theme.set_stylebox("panel", "PanelContainer", panel)
	var btn := StyleBoxFlat.new()
	btn.bg_color = Color(0.18, 0.19, 0.22)
	btn.set_corner_radius_all(6)
	btn.content_margin_left = 10
	btn.content_margin_right = 10
	var btn_hover := btn.duplicate()
	btn_hover.bg_color = Color(0.24, 0.25, 0.28)
	var btn_pressed := btn.duplicate()
	btn_pressed.bg_color = Color(0.72, 0.56, 0.16)
	theme.set_stylebox("normal", "Button", btn)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_color("font_color", "Button", Color(0.92, 0.91, 0.88))
	theme.set_color("font_hover_color", "Button", Color(1, 1, 1))
	theme.set_color("font_pressed_color", "Button", Color(0.12, 0.10, 0.06))
	theme.set_color("font_color", "Label", Color(0.90, 0.90, 0.88))
	return theme


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = _theme
	add_child(root)

	var top_panel := PanelContainer.new()
	top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_left = 12
	top_panel.offset_right = -12
	top_panel.offset_top = 8
	top_panel.offset_bottom = 52
	root.add_child(top_panel)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	top_panel.add_child(top)

	var brand := Label.new()
	brand.text = "MyShop"
	brand.add_theme_font_size_override("font_size", 22)
	brand.add_theme_color_override("font_color", Color(0.92, 0.74, 0.28))
	top.add_child(brand)
	_job = Label.new()
	_job.add_theme_font_size_override("font_size", 16)
	_job.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_job)
	_cash = Label.new()
	_cash.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_cash.add_theme_font_size_override("font_size", 20)
	_cash.add_theme_color_override("font_color", Color(0.82, 0.90, 0.72))
	top.add_child(_cash)

	var views := HBoxContainer.new()
	views.set_anchors_preset(Control.PRESET_TOP_WIDE)
	views.offset_left = 12
	views.offset_right = -200
	views.offset_top = 58
	views.offset_bottom = 100
	views.add_theme_constant_override("separation", 8)
	root.add_child(views)
	_add_view_button(views, "Bay", "bay")
	_add_view_button(views, "Under car", "under")
	_add_view_button(views, "Engine", "engine")
	_add_view_button(views, "Cabin", "cabin")
	var scan := Button.new()
	scan.text = "Scan"
	scan.custom_minimum_size = Vector2(88, 40)
	scan.pressed.connect(game.scan_obd)
	views.add_child(scan)
	var clear := Button.new()
	clear.text = "Clear"
	clear.custom_minimum_size = Vector2(88, 40)
	clear.pressed.connect(game.clear_codes)
	views.add_child(clear)

	var hint_panel := PanelContainer.new()
	hint_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint_panel.offset_left = 12
	hint_panel.offset_right = -12
	hint_panel.offset_top = -126
	hint_panel.offset_bottom = -74
	root.add_child(hint_panel)
	_hint = Label.new()
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_font_size_override("font_size", 15)
	hint_panel.add_child(_hint)

	var tools := HBoxContainer.new()
	tools.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	tools.offset_left = 12
	tools.offset_right = -12
	tools.offset_top = -66
	tools.offset_bottom = -10
	tools.add_theme_constant_override("separation", 8)
	root.add_child(tools)
	for tool in game.TOOLS:
		var button := Button.new()
		button.text = String(tool["label"])
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(96, 50)
		button.pressed.connect(game.select_tool.bind(String(tool["id"])))
		tools.add_child(button)
		_tool_buttons[String(tool["id"])] = button

	_complete = Button.new()
	_complete.text = "Complete job"
	_complete.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_complete.offset_left = -188
	_complete.offset_top = 58
	_complete.offset_right = -12
	_complete.offset_bottom = 100
	_complete.pressed.connect(game.complete_job)
	root.add_child(_complete)

	_overlay = ColorRect.new()
	_overlay.color = Color(0.04, 0.05, 0.06, 0.78)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(_overlay)
	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -270
	card.offset_top = -148
	card.offset_right = 270
	card.offset_bottom = 158
	_overlay.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	_overlay_title = Label.new()
	_overlay_title.add_theme_font_size_override("font_size", 22)
	_overlay_title.add_theme_color_override("font_color", Color(0.92, 0.74, 0.28))
	box.add_child(_overlay_title)
	_overlay_body = RichTextLabel.new()
	_overlay_body.bbcode_enabled = true
	_overlay_body.fit_content = true
	_overlay_body.scroll_active = false
	_overlay_body.custom_minimum_size = Vector2(520, 150)
	box.add_child(_overlay_body)
	_overlay_button = Button.new()
	_overlay_button.custom_minimum_size = Vector2(0, 48)
	_overlay_button.pressed.connect(_on_overlay_pressed)
	box.add_child(_overlay_button)
	_next_car = Button.new()
	_next_car.text = "Different car"
	_next_car.custom_minimum_size = Vector2(0, 40)
	_next_car.pressed.connect(game.next_vehicle)
	box.add_child(_next_car)


func _add_view_button(parent: Control, label: String, view_name: String) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(118, 40)
	button.pressed.connect(game.set_view.bind(view_name))
	parent.add_child(button)


func _update_overlay() -> void:
	var job_prices: Dictionary = game.prices.get("jobs", {}).get(game.job.get("id", ""), {})
	if game.phase == game.Phase.BRIEF:
		_overlay.visible = true
		_overlay_title.text = "Work order"
		_overlay_body.text = "[b]%s[/b]\n%s\n\n%s\n\nCustomer charge: %s\nParts and supplies: %s\nThese prices are illustrative game values." % [
			String(game.job.get("title", "Job")),
			game.vehicle_label(),
			String(game.job.get("complaint", "")),
			game.money(int(job_prices.get("customer_charge_cents", 0))),
			game.money(int(job_prices.get("parts_cost_cents", 0)) + int(job_prices.get("consumables_cost_cents", 0))),
		]
		_overlay_button.text = "Start job"
		_next_car.visible = true
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
		_next_car.visible = false
	else:
		_overlay.visible = false


func _on_overlay_pressed() -> void:
	if game.phase == game.Phase.BRIEF:
		game.accept_job()
	elif game.phase == game.Phase.RESULT:
		game.restart_job()
