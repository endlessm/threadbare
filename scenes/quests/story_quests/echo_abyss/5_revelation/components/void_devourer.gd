# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends CharacterBody2D
class_name EchoAbyssVoidDevourer

enum State {
	PATROLLING,
	CHASING_NPC,
	DEVOURING,
}

const VOID_PARTICLES = preload(
	"res://scenes/quests/lore_quests/quest_002/1_void_runner/components/void_particles.tscn"
)
const IDLE_EMIT_DISTANCE := 90.0 # sqrt(2 * (64.0 ** 2)) is ~90.5

@export var idle_patrol_path: Path2D:
	set = _set_idle_patrol_path

@export var custom_scale: float = 1.0:
	set(value):
		custom_scale = value
		_update_scale()

@export var core_color: Color = Color.BLACK

@export var outline_color: Color = Color.WHITE:
	set(value):
		outline_color = value
		_update_outline_color()

@export var start_progress_ratio: float = 0.0

@export var patrol_direction: int = 1

@export var patrol_speed: float = 90.0

var target_npc: CharacterBody2D = null
var state := State.PATROLLING:
	set = _set_state

var _last_position: Vector2
var _distance_since_emit: float = 0.0
var _live_particles: int = 0
var _temp_patrol_path_nodepath: NodePath = ""

@onready var path_walk_behavior: PathWalkBehavior = %PathWalkBehavior
@onready var follow_walk_behavior: NavigationFollowWalkBehavior = %NavigationFollowWalkBehavior
@onready var npc_detection_area: Area2D = %NPCDetectionArea
@onready var particles_canvas_group: CanvasGroup = %ParticlesCanvasGroup

func _set_idle_patrol_path(new_path) -> void:
	if new_path is NodePath:
		if is_inside_tree():
			idle_patrol_path = get_node(new_path) as Path2D
		else:
			_temp_patrol_path_nodepath = new_path
			return
	else:
		idle_patrol_path = new_path as Path2D

	if path_walk_behavior:
		path_walk_behavior.walking_path = idle_patrol_path

func _set_state(new_state: State) -> void:
	state = new_state
	if not is_node_ready():
		return

	match state:
		State.PATROLLING:
			if path_walk_behavior and path_walk_behavior.walking_path:
				path_walk_behavior.process_mode = Node.PROCESS_MODE_INHERIT
			elif path_walk_behavior:
				path_walk_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			follow_walk_behavior.process_mode = Node.PROCESS_MODE_DISABLED
		State.CHASING_NPC:
			path_walk_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			follow_walk_behavior.process_mode = Node.PROCESS_MODE_INHERIT
		State.DEVOURING:
			path_walk_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			follow_walk_behavior.process_mode = Node.PROCESS_MODE_DISABLED
			velocity = Vector2.ZERO

func _update_scale() -> void:
	scale = Vector2(custom_scale, custom_scale)

func _update_outline_color() -> void:
	if not is_node_ready():
		return
	if particles_canvas_group and particles_canvas_group.material:
		if not particles_canvas_group.material.resource_local_to_scene:
			particles_canvas_group.material = particles_canvas_group.material.duplicate()
		particles_canvas_group.material.set_shader_parameter("outline_color", outline_color)

func _ready() -> void:
	_update_scale()
	_update_outline_color()

	if Engine.is_editor_hint():
		return

	if not _temp_patrol_path_nodepath.is_empty():
		idle_patrol_path = get_node(_temp_patrol_path_nodepath) as Path2D
		_temp_patrol_path_nodepath = ""
	else:
		idle_patrol_path = idle_patrol_path

	if path_walk_behavior:
		path_walk_behavior.walking_path = idle_patrol_path
		path_walk_behavior.direction = patrol_direction
		if path_walk_behavior.speeds:
			path_walk_behavior.speeds = path_walk_behavior.speeds.duplicate()
			path_walk_behavior.speeds.walk_speed = patrol_speed
			path_walk_behavior.speeds.run_speed = patrol_speed

	if idle_patrol_path and start_progress_ratio > 0.0:
		var path_length = idle_patrol_path.curve.get_baked_length()
		var target_offset = path_length * start_progress_ratio
		var local_pos = idle_patrol_path.curve.sample_baked(target_offset)
		global_position = idle_patrol_path.to_global(local_pos)

	state = State.PATROLLING
	_last_position = position
	
	# Connect detection signals
	if npc_detection_area:
		npc_detection_area.body_entered.connect(_on_npc_detected)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	# Emit particles based on distance travelled
	_distance_since_emit += (position - _last_position).length()
	_last_position = position

	if _distance_since_emit >= IDLE_EMIT_DISTANCE:
		_emit_particles()

	match state:
		State.PATROLLING:
			_find_closest_npc()
		State.CHASING_NPC:
			if not is_instance_valid(target_npc) or target_npc.is_queued_for_deletion():
				target_npc = null
				state = State.PATROLLING
				return
			
			# Check distance to target NPC
			var dist = global_position.distance_to(target_npc.global_position)
			if dist < 50.0:
				_devour_npc(target_npc)
		State.DEVOURING:
			pass

func _find_closest_npc() -> void:
	var bodies = npc_detection_area.get_overlapping_bodies()
	var closest: CharacterBody2D = null
	var min_dist := INF
	
	for body in bodies:
		if body is EchoAbyssWanderingNpc and is_instance_valid(body) and not body.is_queued_for_deletion():
			var dist = global_position.distance_to(body.global_position)
			if dist < min_dist:
				min_dist = dist
				closest = body
				
	if closest:
		target_npc = closest
		follow_walk_behavior.target = target_npc
		state = State.CHASING_NPC

func _on_npc_detected(body: Node) -> void:
	if state == State.PATROLLING and body is EchoAbyssWanderingNpc:
		target_npc = body
		follow_walk_behavior.target = target_npc
		state = State.CHASING_NPC

func _devour_npc(npc: EchoAbyssWanderingNpc) -> void:
	state = State.DEVOURING
	
	# Start devouring logic on the NPC side
	if npc.has_method("devour"):
		npc.devour()
	else:
		npc.queue_free()
		
	# Play local devour animation effect (pulsate)
	var tween = create_tween()
	var target_scale = Vector2(1.3 * custom_scale, 1.3 * custom_scale)
	var base_scale = Vector2(custom_scale, custom_scale)
	tween.tween_property(self, "scale", target_scale, 0.25)
	tween.tween_property(self, "scale", base_scale, 0.25)
	
	# Spawn extra particles for devouring
	for i in range(3):
		_emit_particles()
		
	await tween.finished
	
	# Resume patrolling
	target_npc = null
	state = State.PATROLLING

func _emit_particles() -> void:
	_distance_since_emit = 0

	var particles: GPUParticles2D = VOID_PARTICLES.instantiate()
	particles.emitting = true
	particles.self_modulate = core_color
	particles_canvas_group.add_child(particles)
	_live_particles += 1

	await particles.finished

	particles.queue_free()
	_live_particles -= 1
