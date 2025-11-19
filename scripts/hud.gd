extends CanvasLayer

func _ready() -> void:
	update_hud()

func _process(_delta: float) -> void:
	update_hud()

func update_hud() -> void:
	if has_node("BananasLabel"):
		$BananasLabel.text = str(Global.bananas)
	if has_node("VidasLabel"):
		$VidasLabel.text = str(Global.vidas)
