extends CanvasLayer

@export_multiline() var ZonaName:String
var use:bool = false
@onready var ZonaLabel:Label = $PanelContainer/ZonaText

func _ready() -> void:
	ZonaLabel.text = ZonaName
	
func Start() -> void:
	use = true
	show()
	$AutoCloseTimer.stop()
	ZonaLabel.visible_characters = 0
	
	var tween = create_tween()
	
	tween.tween_property(ZonaLabel, "visible_characters", ZonaName.length(), 1.5)
	await tween.finished
	$AutoCloseTimer.start()


func _on_auto_close_timer() -> void:
	hide()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and !use:
		print('jola')
		Start()
