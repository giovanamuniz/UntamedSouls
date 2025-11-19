extends Area3D

const ROT_SPEED = 2 # number of degrees the banana rotates every frame 
@export var hud : CanvasLayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

 
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotate_y(deg_to_rad(ROT_SPEED))
	
func _on_body_entered(body):
	if body.name == "Player": 
		Global.bananas += 1
		
		SoundManager.play_banana_sound()

		var hud_node = get_tree().root.get_node("Level1/HUD")
		if hud_node:
			hud_node.get_node("BananasLabel").text = str(Global.bananas)

		set_collision_layer_value(3, false)
		set_collision_mask_value(1, false)
		$AnimationPlayer.play("bounce")



func _on_animation_player_animation_finished(StringName) -> void:
	queue_free()
