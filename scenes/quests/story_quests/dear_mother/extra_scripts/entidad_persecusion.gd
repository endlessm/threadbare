extends Area2D

## Ajustar velocidad
@export var velocidad: float = 80.0 

@export var objetivo_path: NodePath 
var jugador: Node2D

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	if objetivo_path:
		jugador = get_node(objetivo_path)
		
	anim_sprite.play("walk")

func _process(delta: float) -> void:
	if jugador:
		var direccion: Vector2 = global_position.direction_to(jugador.global_position)
		
		global_position += direccion * velocidad * delta
		
		if direccion.x != 0:
			anim_sprite.flip_h = direccion.x < 0


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.name == "Character":
		get_tree().call_deferred("reload_current_scene")
