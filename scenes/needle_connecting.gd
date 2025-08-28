extends StaticBody2D

@export var disable_ground_collider: bool = false

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var hook_control: HookControl = $HookableArea/HookControl


func _ready() -> void:
	collision_shape_2d.disabled = disable_ground_collider
