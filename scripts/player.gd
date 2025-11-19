extends CharacterBody3D


@export var speed: float = 10.0
@export var jump_force: float = 15.0
@export var gravity: float = 28.0
@export var camera_vertical_offset: float = 3.0


@onready var raycast: RayCast3D = $RayCast3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var armature: Node3D = $Armature
@onready var camera_controller: Node3D = $Camera_Controller


var xform: Transform3D
var velocity_x: float = 0.0

func _physics_process(delta: float) -> void:

	var input_dir: float = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var target_velocity_x: float = input_dir * speed

	if is_on_floor():
		if input_dir != 0.0:
			animation_player.play("Corrida")
		else:
			animation_player.play("Espera")

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		$Soundjump.play()
		velocity.y = jump_force
		$AnimationPlayer.play("Action")



	
	if input_dir != 0.0: velocity.x = lerp(velocity.x, target_velocity_x, speed * delta) 
	else: velocity.x = lerp(velocity.x, 0.0, speed * delta)

	velocity.z = 0.0
	global_position.z = 0.0

	var floor_normal: Vector3 = Vector3.UP
	if is_on_floor() and raycast and raycast.is_colliding():
		floor_normal = raycast.get_collision_normal()
		align_with_floor(floor_normal)
	else:
		align_with_floor(Vector3.UP)

	move_and_slide()


	if armature:
		if input_dir > 0.1:
			armature.rotation_degrees.y = 0.0
		elif input_dir < -0.1:
			armature.rotation_degrees.y = 180.0

	
	if camera_controller:
		var cam_target = Vector3(global_position.x, global_position.y + camera_vertical_offset, camera_controller.global_position.z)
		camera_controller.global_position = camera_controller.global_position.lerp(cam_target, 8.0 * delta)


func align_with_floor(floor_normal: Vector3) -> void:

	xform = global_transform

	xform.basis.y = floor_normal

	xform.basis.x = -xform.basis.z.cross(floor_normal)
	xform.basis = xform.basis.orthonormalized()

	global_transform = global_transform.interpolate_with(xform, 0.15)


func _on_fallzone_body_entered(body: Node3D) -> void:
	SoundManager.play_fall_sound()
	body.perder_vida()

func perder_vida():
	Global.vidas -= 1

	if Global.vidas > 0:
		get_tree().reload_current_scene()
	else:
		Global.vidas = 3
		get_tree().change_scene_to_file("res://scenes/menus/menu_game_over.tscn")


func bounce():
	velocity.y = jump_force * 0.7
	


func _on_switch_level_body_entered(body: Node3D) -> void:
	FadeControl.transition()
	await FadeControl.on_transition_finished
	get_tree().change_scene_to_file("res://scenes/levels/boss.tscn")
