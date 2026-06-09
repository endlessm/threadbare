extends ColorRect

func _ready():
	start_lightning_loop()


func start_lightning_loop() -> void:
	while true:

		await get_tree().create_timer(randf_range(8.0, 15.0)).timeout

		flash()


func flash() -> void:

	visible = true

	modulate.a = 0.8

	await get_tree().create_timer(0.05).timeout

	modulate.a = 0.2

	await get_tree().create_timer(0.03).timeout

	modulate.a = 1.0

	await get_tree().create_timer(0.04).timeout

	modulate.a = 0.0
