extends Control


func _ready() -> void:
	if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		process_mode = Node.PROCESS_MODE_INHERIT
		visible = true
