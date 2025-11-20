extends Node

const MAX_HEALTH = 3
const MIN_HEALTH = 2

var current_health = MIN_HEALTH

signal health_updated

func add_health(amount = 1):
	current_health += amount
	if current_health > MAX_HEALTH:
		current_health = MAX_HEALTH
	
	health_updated.emit()

func take_damage(amount = 1):
	current_health -= amount
	get_tree().reload_current_scene()
	if current_health < 0:
		get_tree().change_scene_to_file("res://scenes/menus/menu_game_over.tscn")
		current_health = 0
	
	print("DANO! Vida é ", current_health)
	health_updated.emit()
