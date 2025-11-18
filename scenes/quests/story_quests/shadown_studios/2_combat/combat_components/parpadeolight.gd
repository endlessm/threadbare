extends PointLight2D

var tween: Tween
@onready var alarm_sound = $AudioStreamPlayer2D

func _ready():
	color = Color(0.449, 0.0, 0.0, 0.8)
	start_alarm_blink()
	alarm_sound.play()

func start_alarm_blink():
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "energy", 0.3, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "energy", 1.5, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
