# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node
## Efectos de cámara/ambiente MIENTRAS el void persigue al jugador:
##   • Aleja un poco la cámara (más visión).
##   • La hace TEMBLAR de forma continua y sutil (sensación de persecución).
##   • Sube una VIÑETA ROJA pulsante en los bordes (tensión).
## Al terminar la persecución, vuelve todo a la normalidad.
##
## Se engancha a los mismos triggers que inician/terminan la persecución
## (EnemyChaseTrigger / EnemyDefeatTrigger) y usa el autoload [code]CameraShake[/code].
## No toca al jugador ni al juego base.

## Área que INICIA la persecución (EnemyChaseTrigger).
@export var chase_start_area: Area2D
## Área que TERMINA la persecución (EnemyDefeatTrigger).
@export var chase_end_area: Area2D
## Zoom durante la persecución (menor = se ve más mapa).
@export var chase_zoom: Vector2 = Vector2(0.8, 0.8)
## Duración de la transición de zoom, en segundos.
@export var zoom_time: float = 0.6
## Activar el temblor de cámara durante la persecución.
@export var enable_shake: bool = true
## Intensidad del temblor (bajo = sutil; el golpe normal del juego usa 30).
@export var shake_intensity: float = 7.0
## Cada cuánto se re-dispara el temblor (s) para que se sienta continuo.
@export var shake_interval: float = 0.8
## El ColorRect de la viñeta roja (ChaseVignette/Vignette). Opcional.
@export var vignette_rect: CanvasItem
## Duración del fundido de la viñeta, en segundos.
@export var vignette_fade: float = 0.5

var _cam: Camera2D
var _normal_zoom: Vector2 = Vector2.ZERO
var _shake_timer: Timer


func _ready() -> void:
	if is_instance_valid(chase_start_area):
		chase_start_area.body_entered.connect(_on_chase_start)
	if is_instance_valid(chase_end_area):
		chase_end_area.body_entered.connect(_on_chase_end)

	_shake_timer = Timer.new()
	_shake_timer.wait_time = shake_interval
	add_child(_shake_timer)
	_shake_timer.timeout.connect(_do_shake)


func _on_chase_start(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	var cam := _resolve_cam()
	if cam:
		create_tween().tween_property(cam, "zoom", chase_zoom, zoom_time)
	if enable_shake:
		_do_shake()
		_shake_timer.start()
	_fade_vignette(1.0)


func _on_chase_end(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	_shake_timer.stop()
	var cam := _resolve_cam()
	if cam and _normal_zoom != Vector2.ZERO:
		create_tween().tween_property(cam, "zoom", _normal_zoom, zoom_time)
	_fade_vignette(0.0)


func _do_shake() -> void:
	if CameraShake.shaker == null:
		return
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	CameraShake.shaker.target = cam
	# time un poco mayor al intervalo → las sacudidas se encadenan (continuo).
	CameraShake.shaker.shake(shake_intensity, shake_interval * 1.5)


func _fade_vignette(to_value: float) -> void:
	if vignette_rect == null or not (vignette_rect.material is ShaderMaterial):
		return
	create_tween().tween_method(_set_vignette, _vignette_value(), to_value, vignette_fade)


func _set_vignette(v: float) -> void:
	if vignette_rect and vignette_rect.material is ShaderMaterial:
		(vignette_rect.material as ShaderMaterial).set_shader_parameter(&"intensity", v)


func _vignette_value() -> float:
	if vignette_rect and vignette_rect.material is ShaderMaterial:
		return (vignette_rect.material as ShaderMaterial).get_shader_parameter(&"intensity")
	return 0.0


func _resolve_cam() -> Camera2D:
	if not is_instance_valid(_cam):
		var player := get_tree().get_first_node_in_group(&"player") as Node
		if player:
			_cam = player.get_node_or_null(^"Camera2D") as Camera2D
	# Guarda el zoom normal la primera vez (antes de alejar).
	if _cam and _normal_zoom == Vector2.ZERO:
		_normal_zoom = _cam.zoom
	return _cam
