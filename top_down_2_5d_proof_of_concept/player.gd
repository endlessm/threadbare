extends CharacterBody3D

const SPEED = 5.0

var collected_object = null

enum State { Running, Idle, Sewing, Unsewing }

var state = State.Idle
@onready var collected_object_node: Sprite3D = $CollectedObjectPivot/CollectedObject


func _physics_process(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if is_instance_valid(collected_object):
		$Label3D.visible = true
		$Label3D.text = "E - Sew"
	elif $DetectSewable.is_colliding():
		$Label3D.visible = true
		$Label3D.text = "E - Unsew"
	else:
		$Label3D.visible = false
	
	$DetectSewable.target_position.x = -1.0 if $AnimatedSprite3D.flip_h else 1.0
	
	if Input.is_action_just_pressed("interact") and state in [State.Idle, State.Running]:
		if is_instance_valid(collected_object):
			unsew()
		elif $DetectSewable.is_colliding():
			sew()

	match state:
		State.Sewing, State.Unsewing:
			return
		State.Idle, State.Running:
			pass
	
	if velocity.x != 0.0:
		$AnimatedSprite3D.flip_h = velocity.x < 0

	if velocity.is_zero_approx():
		state = State.Idle
		$AnimatedSprite3D.play("idle")
	else:
		state = State.Running
		$AnimatedSprite3D.play("walk")

	move_and_slide()

func unsew():
	state = State.Unsewing
	$AnimatedSprite3D.play("unsew")
	await $AnimatedSprite3D.animation_finished
	get_parent().add_child(collected_object)
	collected_object.global_position = collected_object_node.global_position
	collected_object = null
	collected_object_node.visible = false
	state = State.Idle
	
func sew():
	state = State.Sewing
	$AnimatedSprite3D.play("sew")
	await $AnimatedSprite3D.animation_finished
	var overlapping_area = $DetectSewable.get_collider(0)
	var object = overlapping_area.get_parent()
	collected_object = object
	collected_object_node.visible = true
	collected_object_node.texture = object.texture
	collected_object_node.scale = object.scale
	collected_object_node.centered = object.centered
	collected_object_node.offset = object.offset
	collected_object_node.region_enabled = collected_object.region_enabled
	collected_object_node.region_rect = collected_object.region_rect
	object.get_parent().remove_child(object)
	state = State.Idle
