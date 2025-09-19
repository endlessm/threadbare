class_name GitDescribeExtension
extends RefCounted
## Base class for acting on describe strings provided by Godot Git
## Describe.

## Provides convenience methods for managing project settings related
## to Godot Git Describe.
const PluginSettings = preload("res://addons/git_describe/settings.gd")


## Calls [method _set_describe].
func set_describe(describe: String) -> void:
	_set_describe(describe)


## Calls [method _erase_describe].
func erase_describe() -> void:
	_erase_describe()


## Called when the project runs or an export starts. Override to make
## changes with the [param describe] string.
@warning_ignore("unused_parameter")
func _set_describe(describe: String) -> void:
	pass


## Called when the project stops or an export finishes. Override to
## undo the changes made by [method _set_describe].
func _erase_describe() -> void:
	pass
