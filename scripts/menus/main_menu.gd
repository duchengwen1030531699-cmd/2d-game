extends Control

## 主菜单：游戏入口（M0 骨架版）


func _on_start_button_pressed() -> void:
	# M1 之后改为进入关卡选择，目前进入开发场景验证玩法
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_settings_button_pressed() -> void:
	print("设置页面开发中（M2）")


func _on_quit_button_pressed() -> void:
	get_tree().quit()