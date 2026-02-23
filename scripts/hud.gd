@tool
extends CanvasLayer

@export var show_specials: bool = false:
	set = _set_show_specials

@onready var ending_labels = {
	Global.Endings.WIN: %WinEnding,
	Global.Endings.LOSE: %LoseEnding,
}


func _set_show_specials(new_value: bool) -> void:
	show_specials = new_value

	if not is_node_ready():
		return

	for section: Node in [
		%PlayerOneJoypad,
		%PlayerOneKeyboard,
		%PlayerTwoJoypad,
		%PlayerTwoKeyboard,
	]:
		section.get_node("Specials").visible = new_value


func _process(_delta):
	%TimeLeft.text = "%.1f" % Global.timer.time_left


func _ready():
	set_process(false)
	set_physics_process(false)

	show_specials = show_specials

	Global.lives_changed.connect(_on_lives_changed)

	if Engine.is_editor_hint():
		return

	Global.coin_collected.connect(_on_coin_collected)
	Global.game_ended.connect(_on_game_ended)
	Global.timer_added.connect(_on_timer_added)

	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	if DisplayServer.is_touchscreen_available():
		%Start.hide()
		Global.game_started.emit()


func _on_joy_connection_changed(index: int, connected: bool):
	match index:
		0:
			%PlayerOneJoypad.visible = connected
		1:
			%PlayerTwoJoypad.visible = connected


func _unhandled_input(event):
	if (
		(
			event is InputEventKey
			or event is InputEventJoypadButton
			or event is InputEventJoypadMotion
			or event is InputEventScreenTouch
		)
		and %Start.is_visible_in_tree()
	):
		%Start.hide()
		Global.game_started.emit()


func _on_coin_collected():
	set_collected_coins(Global.coins)


func set_collected_coins(coins: int):
	%CollectedCoins.text = "Coins: " + str(coins)


func _on_timer_added():
	%TimeLeft.visible = true
	set_process(true)


func _on_lives_changed():
	set_lives(Global.lives)


func set_lives(lives: int):
	%Lives.offset_right = %Lives.offset_left + lives * %Lives.texture.get_width()


func _on_game_ended(ending: Global.Endings):
	ending_labels[ending].visible = true
