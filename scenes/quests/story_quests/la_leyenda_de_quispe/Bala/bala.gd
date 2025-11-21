extends Area2D

@export var speed: float = 300.0
@export var damage: int = 50
@onready var audio_disparo: AudioStreamPlayer2D = $AudioStreamPlayer2D
var direction: Vector2 = Vector2.RIGHT
var active: bool = false
var owner_type: String = "player" 

func _ready() -> void:
	if audio_disparo:
		audio_disparo.pitch_scale = randf_range(0.9, 1.1)
		audio_disparo.play()
	await get_tree().create_timer(0.1).timeout
	active = true
	if not is_connected("area_entered", Callable(self, "_on_hit")):
		connect("area_entered", Callable(self, "_on_hit"))
	if not is_connected("body_entered", Callable(self, "_on_body_hit")):
		connect("body_entered", Callable(self, "_on_body_hit"))

func _process(delta: float) -> void:
	position += direction * speed * delta

func _on_hit(area: Area2D) -> void:
	if area.has_method("recibir_dano"):
		area.recibir_dano()
		queue_free()

func _on_body_hit(body: Node) -> void:
	if not active: return
	if owner_type == "boss" and body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
		return
	if owner_type == "player" and body.is_in_group("boss"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
		return
	queue_free()

func _on_visible_on_screen_exited() -> void:
	queue_free()
