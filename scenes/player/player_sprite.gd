extends AnimatedSprite2D

@export var character: CharacterBody2D


func _ready() -> void:
	if not character and owner is CharacterBody2D:
		character = owner


func _process(_delta: float) -> void:
	if not character:
		return
	if character.velocity.is_zero_approx():
		play(&"idle")
	else:
		if not is_zero_approx(character.velocity.x):
			flip_h = character.velocity.x < 0
		play(&"walk")
