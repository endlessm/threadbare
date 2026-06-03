extends Node2D

@export var float_height: float = 8.0
@export var float_speed: float = 2.0
@export var attack_time: float = 2.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var start_position: Vector2
var time: float = 0.0
var attacking: bool = false


func _ready() -> void:
	start_position = position
	
	animated_sprite_2d.play("idle")
	
	var timer := Timer.new()
	timer.wait_time = attack_time
	timer.autostart = true
	timer.timeout.connect(attack)
	add_child(timer)


func _process(delta: float) -> void:
	time += delta
	
	var offset_y := sin(time * float_speed) * float_height
	position.y = start_position.y + offset_y


func attack() -> void:
	if attacking:
		return
	
	attacking = true
	animated_sprite_2d.play("attack")


func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "attack":
		attacking = false
		animated_sprite_2d.play("idle")
