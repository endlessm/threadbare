extends CharacterBody2D
## La Serpiente tiene dos modos:
## 1. PATRULLA: camina de lado a lado dentro del jardín, rebotando en los
##    bordes, mientras no hay jugador detectado.
## 2. PERSECUCION: cuando el jugador entra al Area2D de detección, lo
##    persigue para matarlo. Si el jugador sale del área de detección,
##    vuelve a patrullar.
## En AMBOS modos, la serpiente JAMÁS sale de los límites de garden_area:
## el clamp al final de _physics_process es INCONDICIONAL (siempre se
## ejecuta), como última garantía, sin importar qué pase en los modos.

enum State { PATROL, CHASE }

@export var patrol_speed: float = 50.0
@export var chase_speed: float = 40.0
## Área que define los límites del jardín (nodo JardinArea). La serpiente
## nunca puede salir de este rectángulo, ni patrullando ni persiguiendo.
@export var garden_area: Area2D
## Área hija (el nodo "Area2D" que ya tenés bajo Serpiente) que detecta
## cuándo el jugador está cerca y dispara el modo persecución.
@export var detection_area: Area2D
## Distancia de contacto: si la serpiente llega a esta distancia del
## jugador mientras lo persigue, lo derrota.
@export var kill_distance: float = 14.0

var _state: State = State.PATROL
var _detected_player: Node2D = null
var _patrol_dir: float = 1.0

## Límites del jardín. Si JardinArea no está asignado o falla, usamos un
## rectángulo gigante por defecto (para no romper el juego), pero avisamos
## fuerte por consola para que se note enseguida.
var _garden_min: Vector2 = Vector2(-100000, -100000)
var _garden_max: Vector2 = Vector2(100000, 100000)


func _ready() -> void:
	# Esperamos un frame para que garden_area (JardinArea) ya haya
	# configurado sus límites en su propio _ready() antes de leerlos.
	await get_tree().process_frame
	_refresh_garden_bounds()

	if detection_area != null:
		detection_area.body_entered.connect(_on_detection_body_entered)
	else:
		push_warning("Serpiente: no se asignó detection_area; nunca va a perseguir al jugador.")


## Vuelve a leer los límites del jardín desde garden_area. Se puede llamar
## de nuevo en cualquier momento si el jardín cambia en runtime.
func _refresh_garden_bounds() -> void:
	if garden_area == null:
		push_warning("Serpiente: garden_area es null. Usando límites gigantes por defecto (¡la serpiente podría salirse del mapa!).")
		return
	if not garden_area.has_method("get_bounds"):
		push_warning("Serpiente: garden_area no tiene el método get_bounds(). Usando límites gigantes por defecto.")
		return

	var bounds: Array = garden_area.get_bounds()
	if bounds[0] == bounds[1]:
		push_warning("Serpiente: get_bounds() devolvió min==max (rectángulo vacío). Usando límites gigantes por defecto.")
		return

	_garden_min = bounds[0]
	_garden_max = bounds[1]
	print(">>> Serpiente: límites del jardín OK -> min=", _garden_min, " max=", _garden_max)


func _on_detection_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_detected_player = body
		_state = State.CHASE


## Nota: a propósito NO volvemos a PATROL cuando el jugador sale del
## Area2D de detección. Así, una vez que la serpiente te vio, te persigue
## por TODO el jardín (clamp mediante), no solo mientras estés cerca del
## punto donde te detectó. Si querés que en algún momento se "rinda" y
## vuelva a patrullar, avisame y agregamos esa condición.


func _physics_process(delta: float) -> void:
	match _state:
		State.PATROL:
			_process_patrol(delta)
		State.CHASE:
			_process_chase(delta)

	# Clamp INCONDICIONAL: pase lo que pase arriba, la posición final
	# siempre queda dentro de [_garden_min, _garden_max]. Esta es la
	# última línea de defensa contra cualquier forma de "salirse".
	_clamp_to_garden()

	print("pos=", global_position, " state=", State.keys()[_state], " min=", _garden_min, " max=", _garden_max)


func _process_patrol(_delta: float) -> void:
	velocity = Vector2(_patrol_dir * patrol_speed, 0.0)
	move_and_slide()


func _process_chase(_delta: float) -> void:
	if _detected_player == null:
		_state = State.PATROL
		return

	# Perseguimos la posición del jugador recortada a los límites del
	# jardín, para no intentar alcanzar un punto inalcanzable si el
	# jugador está (o se asoma) fuera del área permitida.
	var target_pos: Vector2 = _detected_player.global_position
	target_pos.x = clamp(target_pos.x, _garden_min.x, _garden_max.x)
	target_pos.y = clamp(target_pos.y, _garden_min.y, _garden_max.y)

	# Distancia real al jugador (sin recortar), para decidir si lo matamos.
	var distance_to_player: float = global_position.distance_to(_detected_player.global_position)
	if distance_to_player <= kill_distance:
		if _detected_player.has_method("defeat"):
			_detected_player.defeat()
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# --- Técnica anti-overshoot ---
	# En vez de ir siempre a velocidad máxima y frenar en seco al llegar
	# (lo que causaba zigzag/órbitas), limitamos la velocidad a lo que
	# falta para llegar al objetivo. Así frena solo, naturalmente, sin
	# pasarse de largo ni necesitar lógica de "atasco" aparte.
	var to_target: Vector2 = target_pos - global_position
	var distance_to_target: float = to_target.length()

	if distance_to_target < 0.5:
		velocity = Vector2.ZERO
	else:
		var direction: Vector2 = to_target / distance_to_target
		velocity = direction * min(distance_to_target, chase_speed)

	move_and_slide()


func _clamp_to_garden() -> void:
	var clamped := Vector2(
		clamp(global_position.x, _garden_min.x, _garden_max.x),
		clamp(global_position.y, _garden_min.y, _garden_max.y)
	)
	if clamped == global_position:
		return

	# Si chocó contra el borde horizontal mientras patrullaba, invertimos
	# la dirección de patrulla para que rebote en vez de quedar pegada.
	if _state == State.PATROL and not is_equal_approx(clamped.x, global_position.x):
		_patrol_dir = -_patrol_dir

	global_position = clamped
