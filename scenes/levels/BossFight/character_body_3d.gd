extends CharacterBody3D


@export var speed: float = 10.0
@export var jump_force: float = 15.0
@export var gravity: float = 28.0
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var armature: Node3D = $Armature

# Vida do jogador
var max_hp: int = 1
var current_hp: int = 1

var xform: Transform3D
var velocity_x: float = 0.0

func _ready():
	current_hp = max_hp
	
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

	move_and_slide()

	if armature:
		if input_dir > 0.1:
			armature.rotation_degrees.y = 0.0
		elif input_dir < -0.1:
			armature.rotation_degrees.y = 180.0


func align_with_floor(floor_normal: Vector3) -> void:

	xform = global_transform

	xform.basis.y = floor_normal

	xform.basis.x = -xform.basis.z.cross(floor_normal)
	xform.basis = xform.basis.orthonormalized()

	global_transform = global_transform.interpolate_with(xform, 0.15)

	# --- Verifica colisão com o boss ---
	check_enemy_collision()


func check_enemy_collision():
	# Verifica todas as colisões desta frame
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider == null:
			continue

		# ➜ Colidiu com o boss
		if collider.name == "Enemy" or collider.is_in_group("boss"):
			# --- Jogador CAIU por cima do boss ---
			if velocity.y < 0 and col.get_normal().y > 0.6:
				if collider.has_method("take_damage"):
					collider.take_damage()  # Causa dano no boss
				bounce()
				print("Jogador pisou no boss!")
				return  # Só processa uma colisão por frame

			# --- Jogador colidiu de lado → leva dano ---
			take_damage(1)
			# Knockback simples
			velocity.x = sign(global_position.x - collider.global_position.x) * 6
			velocity.y = 6
			print("Jogador levou dano do boss! HP restante:", current_hp)
			return


func take_damage(amount: int = 1):
	current_hp -= amount
	if current_hp <= 0:
		current_hp = 0
		die()
	else:
		get_tree().reload_current_scene()
		print("Jogador levou dano! HP restante:", current_hp)


func bounce():
	velocity.y = jump_force * 0.7


func die():
	print("Jogador morreu!")
	get_tree().change_scene_to_file("res://scenes/menus/menu_game_over.tscn")
