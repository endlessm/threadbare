extends Node

var collected_count := 0

func add_item():
	collected_count += 1

func reset():
	collected_count = 0
