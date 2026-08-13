extends Control

const COLOR_CREAM := Color("fff8ec")
const COLOR_ORANGE := Color("e7773b")
const COLOR_BROWN := Color("4a3426")
const COLOR_MUTED := Color("806b5a")
const COLOR_PANEL := Color("fffdf8")
const COLOR_LINE := Color("e6d5c4")

var _active_page := "none"
var _nav_buttons: Dictionary = {}
var _coins_label: Label
var _reputation_label: Label
var _materials_label: Label
var _finished_label: Label
var _task_label: Label
var _street: ScrollContainer
var _drawer: PanelContainer
var _drawer_scroll: ScrollContainer
var _page_body: VBoxContainer
var _toast: Label
var _toast_timer: Timer
var _settings_button: Button


func _ready() -> void:
	_build_interface()
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.toast_requested.connect(_show_toast)
	_on_state_changed(GameManager.get_state())
	_nav_buttons["purchase"].grab_focus()


func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = COLOR_CREAM
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 0)
	add_child(layout)

	var header := _panel(Color("f08a4b"), 56)
	var header_content := HBoxContainer.new()
	header_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	header_content.offset_left = 18
	header_content.offset_right = -18
	header_content.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(header_content)
	var title := _label("☀ 晨光街 · 早餐店", 22, Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_content.add_child(title)
	_coins_label = _resource_label("金币 80")
	_reputation_label = _resource_label("口碑 0")
	_materials_label = _resource_label("原料 0 / 20")
	_finished_label = _resource_label("成品 0 / 8")
	for resource_label in [_coins_label, _reputation_label, _materials_label, _finished_label]:
		header_content.add_child(resource_label)
	var settings_button := Button.new()
	settings_button.text = "设置"
	settings_button.custom_minimum_size = Vector2(64, 30)
	settings_button.add_theme_font_size_override("font_size", 13)
	settings_button.add_theme_color_override("font_color", Color.WHITE)
	settings_button.add_theme_stylebox_override("normal", _stylebox(Color("ffffff33"), 6))
	settings_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/settings/settings.tscn"))
	header_content.add_child(settings_button)
	layout.add_child(header)

	var task_panel := _panel(Color("fff1c8"), 40)
	_task_label = _label("特殊订单：普通顾客再购买 3 份后出现", 15, COLOR_BROWN)
	_task_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_task_label.offset_left = 18
	_task_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	task_panel.add_child(_task_label)
	layout.add_child(task_panel)

	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 0)

	_street = ScrollContainer.new()
	_street.set_script(preload("res://scripts/ui/street_scroll.gd"))
	_street.custom_minimum_size = Vector2(260, 0)
	_street.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_street.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_street.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_street.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_street.add_theme_stylebox_override("panel", _stylebox(Color("bce9f2"), 0))
	var street_content := HBoxContainer.new()
	street_content.custom_minimum_size = Vector2(1640, 0)
	street_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	street_content.add_theme_constant_override("separation", 64)
	street_content.alignment = BoxContainer.ALIGNMENT_CENTER
	_street.add_child(street_content)
	street_content.add_child(_street_spacer())
	street_content.add_child(_building_button("供应商", "采购原料", "purchase", Color("a6cf85")))
	street_content.add_child(_building_button("晨光早餐店", "制作 · 库存 · 队列", "craft", Color("ffd36f")))
	street_content.add_child(_building_button("订单板", "特殊订单", "orders", Color("dca46b")))
	street_content.add_child(_building_button("升级招牌", "店铺升级", "upgrades", Color("f0b879")))
	street_content.add_child(_street_spacer())
	content.add_child(_street)

	_drawer = PanelContainer.new()
	_drawer.custom_minimum_size = Vector2(64, 0)
	_drawer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_drawer.add_theme_stylebox_override("panel", _stylebox(COLOR_PANEL, 0, COLOR_LINE))
	var drawer_layout := HBoxContainer.new()
	drawer_layout.add_theme_constant_override("separation", 0)
	_drawer.add_child(drawer_layout)
	var nav := VBoxContainer.new()
	nav.custom_minimum_size = Vector2(64, 0)
	nav.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for page in ["purchase", "craft", "orders", "upgrades"]:
		var text: String = str({"purchase": "采购", "craft": "制作", "orders": "订单", "upgrades": "升级"}[page])
		var button := Button.new()
		button.text = text
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(64, 64)
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 15)
		button.add_theme_color_override("font_color", COLOR_MUTED)
		button.add_theme_color_override("font_hover_color", COLOR_BROWN)
		button.add_theme_color_override("font_pressed_color", COLOR_ORANGE)
		button.add_theme_stylebox_override("normal", _stylebox(Color("fffaf2"), 0))
		button.add_theme_stylebox_override("hover", _stylebox(Color("fff0d0"), 0))
		button.add_theme_stylebox_override("pressed", _stylebox(Color("ffe0a2"), 0))
		button.pressed.connect(func() -> void: _toggle_page(page))
		nav.add_child(button)
		_nav_buttons[page] = button
	drawer_layout.add_child(nav)
	_drawer_scroll = ScrollContainer.new()
	_drawer_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_drawer_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_drawer_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_drawer_scroll.visible = false
	var page_margin := MarginContainer.new()
	page_margin.add_theme_constant_override("margin_left", 14)
	page_margin.add_theme_constant_override("margin_top", 12)
	page_margin.add_theme_constant_override("margin_right", 14)
	page_margin.add_theme_constant_override("margin_bottom", 12)
	_page_body = VBoxContainer.new()
	_page_body.custom_minimum_size = Vector2(268, 0)
	_page_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_body.add_theme_constant_override("separation", 10)
	page_margin.add_child(_page_body)
	_drawer_scroll.add_child(page_margin)
	drawer_layout.add_child(_drawer_scroll)
	content.add_child(_drawer)
	layout.add_child(content)

	_toast = _label("", 16, Color.WHITE)
	_toast.visible = false
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast.custom_minimum_size = Vector2(380, 42)
	_toast.position = Vector2(440, 100)
	_toast.add_theme_stylebox_override("normal", _stylebox(Color("5b4031e8"), 10))
	_toast.z_index = 5
	add_child(_toast)
	_toast_timer = Timer.new()
	_toast_timer.one_shot = true
	_toast_timer.timeout.connect(func() -> void: _toast.visible = false)
	add_child(_toast_timer)


func _toggle_page(page: String) -> void:
	_show_page("none" if _active_page == page else page)


func _show_page(page: String) -> void:
	_active_page = page
	_drawer.custom_minimum_size.x = 64 if page == "none" else 360
	_drawer_scroll.visible = page != "none"
	for page_id in _nav_buttons:
		_nav_buttons[page_id].button_pressed = page_id == page
	if page == "none":
		return
	_rebuild_active_page()


func _rebuild_active_page() -> void:
	for child in _page_body.get_children():
		child.queue_free()
	match _active_page:
		"purchase":
			_build_purchase_page()
		"craft":
			_build_craft_page()
		"orders":
			_build_orders_page()
		"upgrades":
			_build_upgrades_page()


func _build_purchase_page() -> void:
	_page_body.add_child(_page_heading("供应商采购", "一键补满原料库存"))
	var state := GameManager.get_state()
	for item_id in Catalog.INGREDIENTS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var info := _label("%s\n%d 金币 / 份" % [Catalog.INGREDIENTS[item_id]["name"], Catalog.INGREDIENTS[item_id]["price"]], 15, COLOR_BROWN)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var current := int(state["stock"].get(item_id, 0))
		var stock_label := _label("库存 %d" % current, 14, COLOR_MUTED)
		stock_label.name = "StockLabel"
		row.add_child(stock_label)
		_page_body.add_child(_card(row))
	var summary := _label("", 15, COLOR_MUTED)
	summary.name = "PurchaseSummary"
	_page_body.add_child(_card(summary))
	var batch := _action_button("补满采购")
	batch.pressed.connect(func() -> void:
		if GameManager.purchase_batch():
			_rebuild_active_page()
	)
	_page_body.add_child(batch)
	_refresh_purchase_summary()


func _refresh_purchase_summary() -> void:
	if not is_instance_valid(_page_body):
		return
	var summary := _page_body.find_child("PurchaseSummary", true, false) as Label
	if summary == null:
		return
	var state := GameManager.get_state()
	var space := Catalog.material_capacity(state) - _material_count(state)
	summary.text = "当前剩余容量 %d" % max(0, space)


func _build_craft_page() -> void:
	_page_body.add_child(_page_heading("制作与库存", "配方加入串行队列后立即预留材料"))
	_page_body.add_child(_section_label("配方"))
	for recipe_id in Catalog.RECIPES:
		var recipe: Dictionary = Catalog.RECIPES[recipe_id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var detail := "中间品" if int(recipe["price"]) == 0 else "%d 金币" % Catalog.sale_price(GameManager.get_state(), recipe["output"])
		var info := _label("%s\n%s · %.0f 秒 · %s" % [recipe["name"], _ingredient_text(recipe["ingredients"]), Catalog.recipe_duration(GameManager.get_state(), recipe_id), detail], 14, COLOR_BROWN)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var add_button := _action_button("加入队列")
		add_button.pressed.connect(func() -> void: GameManager.enqueue_recipe(recipe_id))
		row.add_child(add_button)
		_page_body.add_child(_card(row))
	var state := GameManager.get_state()
	_page_body.add_child(_section_label("库存与生产队列"))
	var queue_card_content := VBoxContainer.new()
	queue_card_content.add_theme_constant_override("separation", 7)
	queue_card_content.add_child(_label("原料 / 中间品  %d / %d\n可售成品  %d / %d" % [_material_count(state), Catalog.material_capacity(state), state["finished_items"].size(), Catalog.finished_capacity(state)], 14, COLOR_MUTED))
	queue_card_content.add_child(_label("生产队列", 15, COLOR_BROWN))
	if state["queue"].is_empty():
		queue_card_content.add_child(_label("暂无任务", 14, COLOR_MUTED))
	else:
		for job in state["queue"]:
			queue_card_content.add_child(_queue_row(job))
	_page_body.add_child(_card(queue_card_content))


func _build_orders_page() -> void:
	_page_body.add_child(_page_heading("特殊订单", "同一时间仅能接取 1 张"))
	var state := GameManager.get_state()
	if not state["active_order"].is_empty():
		var order: Dictionary = state["active_order"]
		var title := "%s ×%d" % [Catalog.PRODUCT_NAMES[order["target_id"]], order["required"]]
		var status := "订单已完成，可交付" if bool(order["ready"]) else "已预留 %d / %d · 剩余 %.0f 秒" % [order["reserved"], order["required"], order["remaining"]]
		var order_card := VBoxContainer.new()
		order_card.add_theme_constant_override("separation", 8)
		order_card.add_child(_label("%s\n%s" % [title, status], 17, COLOR_BROWN))
		if bool(order["ready"]):
			var deliver := _action_button("交付订单（60 金币 · 口碑 +3）")
			deliver.pressed.connect(func() -> void: GameManager.deliver_order())
			order_card.add_child(deliver)
		_page_body.add_child(_card(order_card))
	elif not state["order_offer"].is_empty():
		var target_id: String = state["order_offer"]["target_id"]
		var offer_card := VBoxContainer.new()
		offer_card.add_theme_constant_override("separation", 8)
		offer_card.add_child(_label("待接订单：%s ×2\n时限 120 秒 · 奖励 60 金币 · 口碑 +3" % Catalog.PRODUCT_NAMES[target_id], 17, COLOR_BROWN))
		var accept := _action_button("接取订单")
		accept.pressed.connect(func() -> void: GameManager.accept_order())
		offer_card.add_child(accept)
		_page_body.add_child(_card(offer_card))
	else:
		var progress := int(state["sold_since_offer"])
		var wait_text := "等待下一单 %.0f 秒" % state["order_cooldown"] if float(state["order_cooldown"]) > 0 else "再售出 %d 份可解锁订单" % max(0, Catalog.ORDER_UNLOCK_SALES - progress)
		_page_body.add_child(_card(_label(wait_text, 17, COLOR_MUTED)))


func _build_upgrades_page() -> void:
	_page_body.add_child(_page_heading("店铺升级", "每项限购一次"))
	var state := GameManager.get_state()
	for upgrade_id in Catalog.UPGRADES:
		var upgrade: Dictionary = Catalog.UPGRADES[upgrade_id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var effect: String = str({"production_speed": "所有配方制作时间减少 20%", "storage": "原料 20→30；成品 8→12", "counter": "商品固定售价提高 20%"}[upgrade_id])
		var prefix := "推荐 · " if bool(upgrade["recommended"]) else ""
		var info := _label("%s%s\n%s" % [prefix, upgrade["name"], effect], 15, COLOR_BROWN)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var button := _action_button("已升级" if bool(state["upgrades"][upgrade_id]) else "%d 金币" % upgrade["cost"])
		button.disabled = bool(state["upgrades"][upgrade_id])
		button.pressed.connect(func() -> void: GameManager.buy_upgrade(upgrade_id))
		row.add_child(button)
		_page_body.add_child(_card(row))


func _queue_row(job: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var recipe: Dictionary = Catalog.RECIPES[job["recipe_id"]]
	var status := "等待空位" if bool(job.get("blocked", false)) else "生产中 %.1f 秒" % float(job["remaining"]) if bool(job["started"]) else "未开始"
	var label := _label("%s · %s" % [recipe["name"], status], 13, COLOR_MUTED)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	if not bool(job["started"]):
		for control in [["↑", -1], ["↓", 1], ["取消", 0]]:
			var button := Button.new()
			button.text = control[0]
			button.pressed.connect(func() -> void:
				if int(control[1]) == 0:
					GameManager.cancel_queued_job(int(job["id"]))
				else:
					GameManager.move_queued_job(int(job["id"]), int(control[1]))
			)
			row.add_child(button)
	return row


func _on_state_changed(state: Dictionary) -> void:
	_coins_label.text = "金币 %d" % state["coins"]
	_reputation_label.text = "口碑 %d" % state["reputation"]
	_materials_label.text = "原料 %d / %d" % [_material_count(state), Catalog.material_capacity(state)]
	_finished_label.text = "成品 %d / %d" % [state["finished_items"].size(), Catalog.finished_capacity(state)]
	_task_label.text = _task_text(state)
	_update_nav_badges(state)
	if _active_page != "none":
		_rebuild_active_page()


func _task_text(state: Dictionary) -> String:
	if not state["active_order"].is_empty():
		var order: Dictionary = state["active_order"]
		if bool(order["ready"]):
			return "特殊订单：%s ×%d 已完成，可前往订单页交付" % [Catalog.PRODUCT_NAMES[order["target_id"]], order["required"]]
		return "特殊订单：%s %d / %d · 剩余 %.0f 秒" % [Catalog.PRODUCT_NAMES[order["target_id"]], order["reserved"], order["required"], order["remaining"]]
	if not state["order_offer"].is_empty():
		return "特殊订单：新的订单已出现，前往订单板接取"
	if float(state["order_cooldown"]) > 0:
		return "特殊订单：下一单将在 %.0f 秒后出现" % state["order_cooldown"]
	return "特殊订单：普通顾客再购买 %d 份后出现" % max(0, Catalog.ORDER_UNLOCK_SALES - int(state["sold_since_offer"]))


func _update_nav_badges(state: Dictionary) -> void:
	_nav_buttons["orders"].text = "订单 ●" if not state["order_offer"].is_empty() or (not state["active_order"].is_empty() and bool(state["active_order"].get("ready", false))) else "订单"
	_nav_buttons["craft"].text = "制作 ●" if not state["queue"].is_empty() and bool(state["queue"][0].get("blocked", false)) else "制作"


func _show_toast(message: String) -> void:
	if _toast == null:
		return
	_toast.text = message
	_toast.visible = true
	_toast_timer.start(2.0)


func _building_button(title: String, detail: String, page: String, color: Color) -> Button:
	var button := Button.new()
	button.text = "%s\n%s" % [title, detail]
	button.custom_minimum_size = Vector2(250, 150)
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", COLOR_BROWN)
	button.add_theme_stylebox_override("normal", _stylebox(color, 16, Color("bd8650")))
	button.pressed.connect(func() -> void: _show_page(page))
	return button


func _street_spacer() -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(80, 1)
	return spacer


func _page_heading(title: String, note: String) -> Control:
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 2)
	var row := HBoxContainer.new()
	var title_label := _label(title, 20, COLOR_BROWN)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_label)
	var close := Button.new()
	close.text = "×"
	close.custom_minimum_size = Vector2(32, 32)
	close.add_theme_font_size_override("font_size", 22)
	close.pressed.connect(func() -> void: _show_page("none"))
	row.add_child(close)
	block.add_child(row)
	block.add_child(_label(note, 13, COLOR_MUTED))
	return block


func _section_label(text: String) -> Label:
	var label := _label(text, 15, COLOR_BROWN)
	return label


func _card(content: Control) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _stylebox(Color("fff8ee"), 10, COLOR_LINE))
	card.add_child(content)
	return card


func _action_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _stylebox(COLOR_ORANGE, 9))
	return button


func _resource_label(text: String) -> Label:
	var label := _label(text, 14, Color.WHITE)
	label.add_theme_stylebox_override("normal", _stylebox(Color("ffffff33"), 10))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(100, 30)
	return label


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _panel(color: Color, minimum_height: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, minimum_height)
	panel.add_theme_stylebox_override("panel", _stylebox(color, 0))
	return panel


func _stylebox(color: Color, radius: int, border_color: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_color = border_color
	style.border_width_left = 1 if border_color != Color.TRANSPARENT else 0
	style.border_width_top = 1 if border_color != Color.TRANSPARENT else 0
	style.border_width_right = 1 if border_color != Color.TRANSPARENT else 0
	style.border_width_bottom = 1 if border_color != Color.TRANSPARENT else 0
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _ingredient_text(ingredients: Dictionary) -> String:
	var parts: Array[String] = []
	for ingredient_id in ingredients:
		parts.append("%s ×%d" % [Catalog.PRODUCT_NAMES.get(ingredient_id, Catalog.INGREDIENTS.get(ingredient_id, {}).get("name", ingredient_id)), ingredients[ingredient_id]])
	return "、".join(parts)


func _material_count(state: Dictionary) -> int:
	var total := 0
	for item_id in ["flour", "egg", "scallion", "batter"]:
		total += int(state["stock"].get(item_id, 0))
	return total
