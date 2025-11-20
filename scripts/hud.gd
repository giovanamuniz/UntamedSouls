extends CanvasLayer

@onready var heart1 = $Heart1
@onready var heart2 = $Heart2
@onready var heart3 = $Heart3

var full_heart_texture = preload("res://assets/images/coracao.png")

func _ready():
	# Conecta ao sinal de VIDA
	Global.health_updated.connect(update_health_display)
	
	# Define a textura dos corações UMA VEZ no início
	heart1.texture = full_heart_texture
	heart2.texture = full_heart_texture
	heart3.texture = full_heart_texture
	
	# Atualiza a vida no início
	update_health_display()


func update_health_display():
	print("PASSO 4: HUD ouviu o sinal! Atualizando corações...")
	
	var current_health = Global.current_health
	print("PASSO 5: HUD vê que a vida é ", current_health)
	
	# --- TESTE DECISIVO ---
	# Vamos ver se o Godot ENCONTROU o nó "Heart3"
	print("O nó Heart1 é: ", heart1)
	print("O nó Heart2 é: ", heart2)
	print("O nó Heart3 é: ", heart3) # <--- APOSTO QUE ESTE VAI DAR "NULL"
	
	heart1.visible = (current_health >= 1)
	heart2.visible = (current_health >= 2)
	heart3.visible = (current_health >= 3)
