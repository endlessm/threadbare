extends Area2D

var transitioning: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not transitioning:
		transitioning = true
		_iniciar_transicion()

func _iniciar_transicion() -> void:
	var overlay: ColorRect = get_node("../CanvasLayer/ColorRect") as ColorRect
	overlay.visible = true
	
	var mat: ShaderMaterial = overlay.material as ShaderMaterial
	var tween: Tween = create_tween()
	
	# Circulo se cierra desde afuera hacia el centro
	tween.tween_method(
		func(val: float) -> void: mat.set_shader_parameter("progress", val),
		1.0, 0.0, 0.8  # de abierto a cerrado en 0.8 segundos
	)
	
	await tween.finished
	SceneSwitcher.change_to_file(
		"res://scenes/quests/story_quests/runa_runner/1_stealth/runa_runner_stealth.tscn"
	)
