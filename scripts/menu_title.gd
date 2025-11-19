extends Control



func _on_play_button_pressed() -> void:
	SoundManager.stop_menu_music()
	SoundManager.play_button_sound()
	get_tree().change_scene_to_file("res://scenes/levels/Level1.tscn")
