# Archivo: projectile_elementals.gd
class_name Projectile
extends RigidBody2D # O el nodo que uses (Area2D, etc.)

# --- VARIABLES REQUERIDAS POR EL ENEMIGO ---
# El script 'ThrowingEnemyelementals' necesita que
# estas variables existan para poder asignarles valor.

var label: String = ""
var color: Color = Color.WHITE
var direction: Vector2 = Vector2.RIGHT
var node_to_follow: Node2D = null
var sprite_frames: SpriteFrames = null
var hit_sound_stream: AudioStream = null
var small_fx_scene: PackedScene = null
var big_fx_scene: PackedScene = null
var trail_fx_scene: PackedScene = null
var speed: float = 400.0
var duration: float = 5.0

# (El enemigo también usa esta en su función _on_got_hit)
var can_hit_enemy: bool = false 

# --- FIN DE VARIABLES REQUERIDAS ---


# ...
# ... Aquí va el resto de tu código de proyectil
# ...

func _ready():
	# ¡Ahora puedes usar las variables que el enemigo te pasó!
	
	# Por ejemplo, si usas un RigidBody2D:
	linear_velocity = direction * speed
	
	# Si usas un Area2D o CharacterBody2D, lo harías en _physics_process
	
	# Autodestrucción después del tiempo de vida
	await get_tree().create_timer(duration).timeout
	queue_free()


# Ejemplo de cómo se movería si NO fuera un RigidBody2D
#func _physics_process(delta):
#	global_position += direction * speed * delta


# Ejemplo de cómo detectar al jugador
func _on_body_entered(body):
	
	# Opción 1: Verificamos si es un MURO
	if body.is_in_group("walls"):
		# Destruimos el proyectil
		queue_free()
# --- ¡FUNCIÓN SIMPLIFICADA! ---
# La bala ya NO se preocupa por los enemigos.
