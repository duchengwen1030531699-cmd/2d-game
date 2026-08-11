extends Control

## 主菜单：晨光街 M1 经营原型入口。


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_settings_button_pressed() -> void:
	print("重新开始功能将在 M1 存档界面中提供")


func _on_quit_button_pressed() -> void:
	get_tree().quit()
