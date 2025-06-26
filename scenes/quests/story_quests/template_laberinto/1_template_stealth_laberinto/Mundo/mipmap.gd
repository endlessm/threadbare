extends SubViewport

@onready var camera_2d: Camera2D = $Camera2D
@onready var viewport_container: SubViewportContainer = get_parent() 


var is_visible: bool = true 

func _ready():
	viewport_container.visible = is_visible

func _physics_process(delta):
	var player = owner.find_child("Player")
	if player:
		camera_2d.position = player.position
	
	# visibilidad con la tecla M
	if Input.is_action_just_pressed("ui_m"):  
		is_visible = !is_visible
		viewport_container.visible = is_visible
