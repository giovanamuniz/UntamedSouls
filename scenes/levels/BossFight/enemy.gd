extends CharacterBody3D

# --- Configurações do Jogo ---
const GRAVITY_VAL: float = 9.8
const CHARGE_SPEED: float = 12.0
const ROTATION_SPEED: float = 8.0
@export var max_hp: int = 3

@onready var head_hitbox: Area3D = $HeadHitbox
@onready var attack_hitbox: Area3D = $AttackHitbox

var is_attacking: bool = false

# Referências de Cena
@export var animation_player: AnimationPlayer
@export var wall_target_left: Marker3D
@export var wall_target_right: Marker3D

# Nomes das Animações 
const ANIMATION_IDLE = "Idle-BOSS"
const ANIMATION_CHARGE = "Corrida"
const ANIMATION_VULNERABLE = "Vulnaravel"
const ANIMATION_DEFEAT = "Morte"
const ANIMATION_RISING = "levantando"

# --- Estados ---
enum BossState { IDLE, CHARGING_AT, VULNERABLE }

var current_hp: int
var current_state: BossState = BossState.IDLE
var start_position: Vector3
var target_position: Vector3

signal health_changed(new_hp)
signal boss_defeated


# -------------------------------------------------------------------
# Log de estado
# -------------------------------------------------------------------
func log_state():
	match current_state:
		BossState.IDLE:
			print("Estado: IDLE (parado / esperando)")
		BossState.CHARGING_AT:
			print("Estado: ATACANDO (investida)")
		BossState.VULNERABLE:
			print("Estado: VULNERÁVEL (pode receber dano)")
# -------------------------------------------------------------------


func _ready():
	current_hp = max_hp
	health_changed.emit(current_hp)
	start_position = global_position

	await get_tree().create_timer(0.5).timeout
	start_new_cycle()
	
	# Conecta hitbox da cabeça
	if is_instance_valid(head_hitbox):
		head_hitbox.body_entered.connect(_on_head_hitbox_body_entered)

	# Configura hitbox de ataque
	if is_instance_valid(attack_hitbox):
		attack_hitbox.monitoring = false
		attack_hitbox.body_entered.connect(_on_attack_hitbox_body_entered)


# -------------------------------------------------------------------
# HITBOX DA CABEÇA
# -------------------------------------------------------------------
func _on_head_hitbox_body_entered(body: Node) -> void:
	print("HeadHitbox entrou:", body.name)
	var is_player := false
	if body is Node:
		if body.name == "Bob":
			is_player = true
		elif body.is_in_group("player"):
			is_player = true
		if not is_player:
			return
			
		var vy = 0.0
		if body.has_method("get_velocity"):
			vy = body.get_velocity().y
		elif "velocity" in body:
			vy = body.velocity.y
		else:
			return

		if vy < 0.0 and current_state == BossState.VULNERABLE:
			if is_instance_valid(head_hitbox):
				head_hitbox.monitoring = false

			if has_method("take_damage"):
				take_damage()

			if body.has_method("bounce"):
				body.bounce()
			elif "velocity" in body and "jump_force" in body:
				body.velocity.y = body.jump_force * 0.7
				await get_tree().create_timer(0.12).timeout

			if is_instance_valid(head_hitbox):
				head_hitbox.monitoring = true


# -------------------------------------------------------------------
# HITBOX DE ATAQUE
# -------------------------------------------------------------------
func _on_attack_hitbox_body_entered(body: Node) -> void:
	if not is_attacking:
		return  # Só funciona durante a investida

	var is_player := false
	if body.name == "Bob" or body.is_in_group("player"):
		is_player = true

	if not is_player:
		return

	# Causa dano ao jogador
	if body.has_method("take_damage"):
		body.take_damage(1)

	# Aplica pequeno knockback
	if body.has_method("apply_knockback"):
		body.apply_knockback(global_position)
	elif "velocity" in body:
		body.velocity.x = sign(body.global_position.x - global_position.x) * 8
		body.velocity.y = 6



# -------------------------------------------------------------------
# Animações
# -------------------------------------------------------------------
func play_animation(anim_name: String):
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)


# -------------------------------------------------------------------
# Processamento Físico
# -------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	match current_state:
		BossState.IDLE:
			velocity.x = 0
			velocity.z = 0

		BossState.CHARGING_AT:
			move_charge(delta)

		BossState.VULNERABLE:
			velocity.x = 0
			velocity.z = 0

	move_and_slide()



# -------------------------------------------------------------------
# Ciclo de ataque
# -------------------------------------------------------------------
func start_new_cycle():
	current_state = BossState.IDLE
	log_state()
	play_animation(ANIMATION_IDLE)

	if not is_instance_valid(wall_target_left) or not is_instance_valid(wall_target_right):
		print("ERRO: Alvos de parede inválidos.")
		return

	var left_x = wall_target_left.global_position.x
	var right_x = wall_target_right.global_position.x

	# Escolhe a parede oposta
	if global_position.x < (left_x + right_x) / 2.0:
		target_position = wall_target_right.global_position
	else:
		target_position = wall_target_left.global_position

	target_position.y = global_position.y

	await get_tree().create_timer(1.5).timeout

	current_state = BossState.CHARGING_AT
	log_state()
	play_animation(ANIMATION_CHARGE)

	look_at(target_position, Vector3.UP)

	var direction = (target_position - global_position).normalized()
	velocity.x = direction.x * CHARGE_SPEED
	velocity.z = direction.z * CHARGE_SPEED

	# >>> ATIVA A HITBOX DE ATAQUE <<<
	is_attacking = true
	if is_instance_valid(attack_hitbox):
		attack_hitbox.monitoring = true



# -------------------------------------------------------------------
# Movimento da investida
# -------------------------------------------------------------------
func move_charge(delta: float):
	var distance_to_target = global_position.distance_to(target_position)

	if distance_to_target < CHARGE_SPEED * delta * 1.1:
		handle_wall_collision()



# -------------------------------------------------------------------
# Colisão com parede → Vulnerável
# -------------------------------------------------------------------
func handle_wall_collision():
	if current_state != BossState.CHARGING_AT:
		return

	# >>> DESATIVA HITBOX DE ATAQUE <<<
	is_attacking = false
	if is_instance_valid(attack_hitbox):
		attack_hitbox.monitoring = false

	var reverse_impact_speed = -1.0
	var rising_duration = 1.2

	animation_player.play(ANIMATION_RISING, -1.0, reverse_impact_speed)

	await get_tree().create_timer(rising_duration / abs(reverse_impact_speed)).timeout

	velocity.x = 0
	velocity.z = 0
	global_position.x = target_position.x
	global_position.z = target_position.z

	current_state = BossState.VULNERABLE
	log_state()
	play_animation(ANIMATION_VULNERABLE)

	await get_tree().create_timer(2.0).timeout

	if current_state == BossState.VULNERABLE:
		play_animation(ANIMATION_RISING)
		await get_tree().create_timer(rising_duration).timeout

		current_state = BossState.IDLE
		log_state()
		play_animation(ANIMATION_IDLE)

		rotate_y(deg_to_rad(180))
		get_tree().create_timer(1.0).timeout.connect(start_new_cycle)



# -------------------------------------------------------------------
# RECEBENDO DANO
# -------------------------------------------------------------------
func take_damage():
	if current_state == BossState.VULNERABLE:

		current_hp -= 1
		health_changed.emit(current_hp)

		print("Boss tomou dano! HP restante:", current_hp)

		current_state = BossState.IDLE
		log_state()
		play_animation(ANIMATION_IDLE)

		if current_hp <= 0:
			die()
		else:
			get_tree().create_timer(0.5).timeout.connect(start_new_cycle)



# -------------------------------------------------------------------
# MORTE
# -------------------------------------------------------------------
func die():
	print("BOSS DERROTADO!")
	current_state = BossState.IDLE
	log_state()

	play_animation(ANIMATION_DEFEAT)
	boss_defeated.emit()

	await get_tree().create_timer(3.0).timeout
	queue_free()
