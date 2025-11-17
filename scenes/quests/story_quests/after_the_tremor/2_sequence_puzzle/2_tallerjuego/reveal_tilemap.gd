extends Node

@export var puzzle: SequencePuzzle
@export var tilemap_layer: Node

func _ready():
	if puzzle:
		puzzle.solved.connect(_on_puzzle_solved)

func _on_puzzle_solved():
	if tilemap_layer:
		tilemap_layer.visible = true
