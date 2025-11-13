extends RigidBody2D

var speed: float = 900.0
var direction: Vector2 = Vector2.ZERO 

@export var min_speed_to_die: float = 10.0 

@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var animated_sprite: AnimatedSprite2D = $VisibleThings/AnimatedSprite2D

func _ready():
	# --- ¡CAMBIO! ---
	# Añadimos la bala al grupo "bullet"
	add_to_group("bullet")

	# (Conecta las señales 'body_entered' y 'timeout' en el editor)
	
	animated_sprite.play("default")
	lifetime_timer.start()
	linear_velocity = direction * speed

func _physics_process(delta):
	if linear_velocity.length_squared() > 0:
		rotation = linear_velocity.angle()
	
	if linear_velocity.length_squared() < min_speed_to_die * min_speed_to_die:
		queue_free() 

func _on_lifetime_timer_timeout():
	queue_free() 

# --- ¡FUNCIÓN SIMPLIFICADA! ---
# La bala ya NO se preocupa por los enemigos.
func _on_body_entered(body):
	
	# 1. Ignorar al jugador
	if body.is_in_group("player"):
		return 
		
		

	# 2. Comprobar si es un MURO (walls)
	if body.is_in_group("walls"):
		print("Bala: ¡Reboté en un muro!")
		# Dejamos que el PhysicsMaterial haga el rebote
		return 
		
	# 3. Si choca con cualquier otra cosa (que no sea player, wall)
	queue_free()
