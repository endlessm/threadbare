class_name CustomPlayer extends Player

@export var duration_animation_sword: float = .3

@onready var sword_area: Area2D = $SwordArea2D
var can_attack: bool = true

func _ready() -> void:
	super._ready()
	sword_area.body_entered.connect(_on_sword_area_body_entered)
	sword_area.monitoring = false

func _process(delta: float) -> void:
	super._process(delta)
	if Input.is_action_just_pressed("ui_accept") and can_attack:
		_do_attack()

func _do_attack() -> void:
	can_attack = false
	
	sword_area.monitoring = true
	
	await get_tree().create_timer(duration_animation_sword).timeout
	sword_area.monitoring = false
	can_attack = true

func swing_sword():
	sword_area.monitoring = true

func stop_swing_sword():
	sword_area.monitoring = false

func _on_sword_area_body_entered(body: Node) -> void:
	if not body.is_in_group("guard_enemy"):
		return
	
	var enemy := body as CustomGuard
	if enemy:
		enemy.recive_damage(25)
