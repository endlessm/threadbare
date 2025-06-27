extends CanvasModulate

var time_passed = 0.0
var is_dark = true

func _process(delta):
	
	time_passed += delta
	
	if time_passed >= 3.0:
		if is_dark:
			color = Color(0.2, 0.3, 0.5) 
			is_dark = false
		else:
			color = Color(0.0, 0.0, 0.2)
			is_dark = true
		time_passed = 0.0
