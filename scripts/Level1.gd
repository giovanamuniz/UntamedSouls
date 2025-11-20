extends Node3D

var scene_path: String = "res://scenes/levels/level_1.tscn"
var first_scene_path: String = "res://scenes/levels/level_1.tscn"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SoundManager.play_level_music()
	
