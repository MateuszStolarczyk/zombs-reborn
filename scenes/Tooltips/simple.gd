extends PanelContainer

# Ta funkcja wykonuje się automatycznie w każdej klatce gry
func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()
