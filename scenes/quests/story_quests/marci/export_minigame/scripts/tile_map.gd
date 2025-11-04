extends TileMap

@export var chunk_scene: PackedScene
@export var chunk_size := 512
@onready var player := get_tree().get_first_node_in_group("player")

var loaded_chunks = {}

func _process(delta):
	if player == null:
		return

	var player_chunk = Vector2i(
		int(player.position.x / chunk_size),
		int(player.position.y / chunk_size)
	)

	for x in range(player_chunk.x - 1, player_chunk.x + 2):
		for y in range(player_chunk.y - 1, player_chunk.y + 2):
			var key = Vector2i(x, y)
			if not loaded_chunks.has(key):
				var chunk = chunk_scene.instantiate()
				chunk.position = key * chunk_size
				add_child(chunk)
				loaded_chunks[key] = chunk
