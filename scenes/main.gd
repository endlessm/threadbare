extends Node2D

const BULLET = preload("res://scenes/bullet.tscn")
@onready var timer: Timer = %Timer
@onready var bullet_marker: Marker2D = %BulletMarker

func _ready() -> void:
	timer.timeout.connect(_on_timeout)
	
func _on_timeout() -> void:
	var bullet = BULLET.instantiate()
	bullet.position = bullet_marker.position
	bullet.linear_velocity = bullet.linear_velocity.rotated(randf_range(-PI/8, PI/8))
	add_child(bullet)
