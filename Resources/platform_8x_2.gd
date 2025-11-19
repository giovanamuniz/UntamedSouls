extends AnimatableBody3D

@export var position_a := Vector3()
@export var position_b := Vector3()
@export var time : float = 2.0
@export var pause : float = 0.7

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	move()

func move(): 
	var move_tween = create_tween()
	move_tween.tween_property(self, "position", position_b, time).set_trans(Tween.TRANS_CUBIC).set_delay(pause)
	move_tween.tween_property(self, "position", position_a, time).set_trans(Tween.TRANS_CUBIC).set_delay(pause)
	await get_tree().create_timer(2 * time + 2 * pause).timeout
	move()
