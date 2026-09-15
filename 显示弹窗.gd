extends Control

func _ready() -> void:
	await get_tree().process_frame
	get_window().hide()
	_show_first_dialog()


func _show_first_dialog() -> void:
	DisplayServer.dialog_show(
		"缺少Player",
		"⚠️ 无法启动此程序，因为缺少Player。",
		PackedStringArray(["确定"]),
		func(button_index: int):
			if button_index == 0:
				_show_second_dialog()
	)


func _show_second_dialog() -> void:
	DisplayServer.dialog_show(
		"自动寻找Player",
		"正在寻找相关的Player...",
		PackedStringArray(["确定"]),
		func(button_index: int):
			if button_index == 0:
				_show_Third_dialog()
	)  
	
func _show_Third_dialog() -> void:
	DisplayServer.dialog_show(
		"自动寻找Player",
		"正在寻找相关的Player...",
		PackedStringArray([""]),
		func(button_index: int):
			if button_index == 0:
				get_window().show()
	) 
