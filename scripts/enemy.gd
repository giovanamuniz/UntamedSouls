extends CharacterBody3D


var speed = 10.0
var gravity: float = 9.8
@export var direction := Vector2(-1,0)
@export var turns_around_at_edges := true
var turning := false
var xform: Transform3D

func _physics_process(delta: float) -> void:
	
	velocity.x = speed * direction.x
	velocity.y = speed * direction.y
	
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		

	move_and_slide()
	
	if is_on_wall() and not turning:
		turn_around()
		
	if not $RayCast3D.is_colliding() and is_on_floor() and not turning and turns_around_at_edges:
		turn_around()
		

func turn_around():
		turning = true # boolean: recognized current state
		var dir = direction # backup direction (to restore opposite of later)
		direction = Vector2.ZERO # set directoin to 0
		var turn_tween = create_tween() # create teewn variable
		turn_tween.tween_property(self, "rotation_degrees", Vector3(0,180,0), 0.6).as_relative() # rotate º180º
		
		await get_tree().create_timer(0.6).timeout # pause 0.6 secs
		
		direction.x = dir.x * -1 # set changed direction (from backup)
		direction.y = dir.y * -1 # set changed direction (from backup)
		turning = false # end turning state
		

func _on_sides_checker_body_entered(body: Node3D) -> void:
	SoundManager.play_enemy_sound()
	Global.take_damage()


	

func _on_top_checker_body_entered(body: Node3D) -> void:
	$AnimationPlayer.play("Morte-capanga")
	$Soundsquash.play()
	body.bounce()
	$SidesChecker.set_collision_mask_value(1, false)
	$TopChecker.set_collision_mask_value(1, false)
	direction = Vector2.ZERO
	speed = 0
	await get_tree().create_timer(1.0).timeout
	queue_free()
