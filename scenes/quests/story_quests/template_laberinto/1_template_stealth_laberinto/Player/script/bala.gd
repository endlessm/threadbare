extends Area2D

@export var speed: float = 500.0
var direction: Vector2 = Vector2.ZERO
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var impactando := false

func _ready():
	animated_sprite_2d.play("bala_recorrido")
	connect("body_entered", self._on_body_entered)
	animated_sprite_2d.connect("animation_finished", self._on_animacion_terminada)

func _process(delta: float) -> void:
	if not impactando:
		position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		if "recibir_daño" in body:
			body.recibir_daño(20)
		_reproducir_impacto()
	elif body.is_in_group("wall") or body is TileMap:
		print("🧱 Impactó una pared")
		_reproducir_impacto()

func _reproducir_impacto():
	impactando=true
	var frames := animated_sprite_2d.sprite_frames
	frames.set_animation_loop("impacto_bala", false)
	animated_sprite_2d.play("impacto_bala")

func _on_animacion_terminada():
	if animated_sprite_2d.animation == "impacto_bala":
		queue_free()
