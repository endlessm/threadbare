# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
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

func _ready() -> void:
	if not _temp_patrol_path_nodepath.is_empty():
		idle_patrol_path = get_node(_temp_patrol_path_nodepath) as Path2D
		_temp_patrol_path_nodepath = ""
	else:
		idle_patrol_path = idle_patrol_path

	if path_walk_behavior:
		path_walk_behavior.walking_path = idle_patrol_path

	state = State.PATROLLING
	_last_position = position
	
	# Connect detection signals
	npc_detection_area.body_entered.connect(_on_npc_detected)

func _physics_process(delta: float) -> void:
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
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.25)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.25)
	
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
	particles_canvas_group.add_child(particles)
	_live_particles += 1

	await particles.finished

	particles.queue_free()
	_live_particles -= 1
