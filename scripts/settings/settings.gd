extends Control

const COLOR_CREAM := Color("fff8ec")
const COLOR_ORANGE := Color("e7773b")
const COLOR_BROWN := Color("4a3426")
const COLOR_MUTED := Color("806b5a")
const COLOR_PANEL := Color("fffdf8")
const COLOR_LINE := Color("e6d5c4")

var _back_button: Button


func _ready() -> void:
	_build_interface()


func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = COLOR_CREAM
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 16)
	layout.offset_left = 340
	layout.offset_right = -340
	layout.offset_top = 120
	layout.offset_bottom = -120
	add_child(layout)

	var title := _label("设置", 28, COLOR_BROWN)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)

	layout.add_child(_section_label("音频"))

	var music_row := HBoxContainer.new()
	music_row.add_theme_constant_override("separation", 12)
	var music_label := _label("音乐音量", 15, COLOR_BROWN)
	music_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	music_row.add_child(music_label)
	var music_slider := HSlider.new()
	music_slider.min_value = 0.0
	music_slider.max_value = 100.0
	music_slider.step = 1.0
	music_slider.value = 80.0
	music_slider.custom_minimum_size = Vector2(180, 0)
	music_row.add_child(music_slider)
	layout.add_child(_card(music_row))

	var sfx_row := HBoxContainer.new()
	sfx_row.add_theme_constant_override("separation", 12)
	var sfx_label := _label("音效音量", 15, COLOR_BROWN)
	sfx_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sfx_row.add_child(sfx_label)
	var sfx_slider := HSlider.new()
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 100.0
	sfx_slider.step = 1.0
	sfx_slider.value = 80.0
	sfx_slider.custom_minimum_size = Vector2(180, 0)
	sfx_row.add_child(sfx_slider)
	layout.add_child(_card(sfx_row))

	layout.add_child(_section_label("游戏"))

	var restart_row := HBoxContainer.new()
	restart_row.add_theme_constant_override("separation", 12)
	var restart_info := _label("清除当前存档并重新开始经营。", 14, COLOR_MUTED)
	restart_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restart_row.add_child(restart_info)
	var restart_button := _action_button("重新开始")
	restart_button.pressed.connect(_on_restart_pressed)
	restart_row.add_child(restart_button)
	layout.add_child(_card(restart_row))

	var menu_row := HBoxContainer.new()
	menu_row.add_theme_constant_override("separation", 12)
	var menu_info := _label("返回主菜单，经营进度将保留。", 14, COLOR_MUTED)
	menu_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_row.add_child(menu_info)
	var menu_button := _action_button("主菜单")
	menu_button.pressed.connect(_on_menu_pressed)
	menu_row.add_child(menu_button)
	layout.add_child(_card(menu_row))

	layout.add_child(_section_label("关于"))

	var about_card := _card(_label("《晨光街》M1 原型 · 横板模拟经营\n引擎：Godot 4.7.1", 14, COLOR_MUTED))
	layout.add_child(about_card)

	_back_button = _action_button("返回")
	_back_button.pressed.connect(_on_back_pressed)
	layout.add_child(_back_button)


func _on_restart_pressed() -> void:
	SaveManager.clear_save()
	print("存档已清除，将重新开始")
	get_tree().quit(0)


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _section_label(text: String) -> Control:
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


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


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
