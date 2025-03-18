class_name Shaker
extends Node

## The node to target. Defaults to parent.
@export var target_node: Node;
## The property to shake.
@export var target_property: StringName = "";
## Minimum value.
@export var min_value: float = 0.0;
## Maximum value.
@export var max_value: float = 0.0;
## Shake until manually disabled.
@export var constant: bool = false;
## Start automatically when ready.
@export var auto_start: bool = false;
## Shake duration. Only applies if constant == false.
@export_range(0.0, 3600, 0.01) var duration: float = 0.8;
## Shake fall off curve. Only applies if constant == false.
@export var fall_off: Curve; 
var timer: Timer = Timer.new();


func _ready() -> void:
	if !target_node: target_node = get_parent();
	
	add_child(timer);
	timer.wait_time = duration;
	timer.timeout.connect(stop);
	
	set_process(var_is_valid(target_node, target_property) and constant);
	
	if auto_start: start();
	
func var_is_valid(node: Node, property: String) -> bool:
	return property in node;

func start(time_sec: float = -1.0) -> void:
	timer.start(time_sec);
	if !var_is_valid(target_node, target_property): print("%s does not have a variable called %s" % [target_node, target_property]);
	else: set_process(true);
	
func stop() -> void:
	timer.stop();
	set_process(false);

func _process(_delta: float) -> void:
	match typeof(target_node.get(target_property)):
		TYPE_INT: 
			target_node.set(target_property,
				int(randf_range(min_value, max_value) * get_curve_interpolation(fall_off, duration, timer.time_left, constant))
				);
		
		TYPE_FLOAT:
			target_node.set(target_property,
				randf_range(min_value, max_value) * get_curve_interpolation(fall_off, duration, timer.time_left, constant)
				);
			
		TYPE_VECTOR2I:
			target_node.set(target_property, Vector2i(
				int(randf_range(min_value, max_value) * get_curve_interpolation(fall_off, duration, timer.time_left, constant)),
				int(randf_range(min_value, max_value) * get_curve_interpolation(fall_off, duration, timer.time_left, constant))
				));
		
		TYPE_VECTOR2:
			target_node.set(target_property, Vector2(
				randf_range(min_value, max_value) * get_curve_interpolation(fall_off, duration, timer.time_left, constant),
				randf_range(min_value, max_value) * get_curve_interpolation(fall_off, duration, timer.time_left, constant)
				));
		
		TYPE_VECTOR3I:
			target_node.set(target_property, Vector3i(
				int(randf_range(min_value, max_value) * get_curve_interpolation(fall_off, duration, timer.time_left, constant)),
				int(randf_range(min_value, max_value) * get_curve_interpolation(fall_off, duration, timer.time_left, constant)),
				int(randf_range(min_value, max_value) * get_curve_interpolation(fall_off, duration, timer.time_left, constant))
				));
		
		TYPE_VECTOR3:
			target_node.set(target_property, Vector3(
				randf_range(min_value, max_value) * get_curve_interpolation(fall_off, duration, timer.time_left, constant),
				randf_range(min_value, max_value) * get_curve_interpolation(fall_off, duration, timer.time_left, constant),
				randf_range(min_value, max_value) * get_curve_interpolation(fall_off, duration, timer.time_left, constant)
				));
		
		TYPE_VECTOR4I:
			target_node.set(target_property, Vector4i(
				int(randf_range(min_value, max_value) * get_curve_interpolation(fall_off, duration, timer.time_left, constant)),
				int(randf_range(min_value, max_value) * get_curve_interpolation(fall_off, duration, timer.time_left, constant)),
				int(randf_range(min_value, max_value) * get_curve_interpolation(fall_off, duration, timer.time_left, constant)),
				int(randf_range(min_value, max_value) * get_curve_interpolation(fall_off, duration, timer.time_left, constant))
				));
		
		TYPE_VECTOR4:
			target_node.set(target_property, Vector4(
				randf_range(min_value, max_value) * get_curve_interpolation(fall_off, duration, timer.time_left, constant),
				randf_range(min_value, max_value) * get_curve_interpolation(fall_off, duration, timer.time_left, constant),
				randf_range(min_value, max_value) * get_curve_interpolation(fall_off, duration, timer.time_left, constant),
				randf_range(min_value, max_value) * get_curve_interpolation(fall_off, duration, timer.time_left, constant)
				));
		
		_:
			print_debug("Unmatched var type");

func get_curve_interpolation(curve: Curve, max_time: float, time_left: float, _constant: bool) -> Variant:
	if !_constant:
		return 1 - curve.sample(time_left / max_time);
		
	else:
		return 1;
