extends Control

const GRID_SIZE = 5
const CELL_SIZE = 60
const BORDER_WIDTH = 2
const MAX_LEVEL = 4

var colors = [
	Color.RED,
	Color.BLUE,
	Color.GREEN,
	Color.YELLOW,
	Color.MAGENTA
]

var grid = []
var start_points = {}
var end_points = {}
var current_path = []
var current_color = -1
var is_drawing = false
var paths = {}
var current_level = 1

func _ready():
	custom_minimum_size = Vector2(GRID_SIZE * CELL_SIZE, GRID_SIZE * CELL_SIZE)
	size = custom_minimum_size
	initialize_grid()
	create_puzzle()
	mouse_filter = Control.MOUSE_FILTER_PASS

func initialize_grid():
	grid = []
	for i in range(GRID_SIZE):
		var row = []
		for j in range(GRID_SIZE):
			row.append(-1)
		grid.append(row)

func create_puzzle():
	start_points.clear()
	end_points.clear()
	paths.clear()
	current_path.clear()
	current_color = -1
	is_drawing = false
	initialize_grid()
	
	match current_level:
		1:
			start_points[0] = Vector2(1, 2)
			end_points[0] = Vector2(3, 2)
			grid[2][1] = 0
			grid[2][3] = 0
			
		2:
			start_points[0] = Vector2(1, 1)
			end_points[0] = Vector2(3, 1)
			grid[1][1] = 0
			grid[1][3] = 0
			
			start_points[1] = Vector2(1, 3)
			end_points[1] = Vector2(3, 3)
			grid[3][1] = 1
			grid[3][3] = 1
			
		3:
			start_points[0] = Vector2(0, 0)
			end_points[0] = Vector2(2, 0)
			grid[0][0] = 0
			grid[0][2] = 0
			
			start_points[1] = Vector2(4, 4)
			end_points[1] = Vector2(2, 4)
			grid[4][4] = 1
			grid[4][2] = 1
			
		4:
			start_points[0] = Vector2(0, 0)
			end_points[0] = Vector2(4, 0)
			grid[0][0] = 0
			grid[0][4] = 0
			
			start_points[1] = Vector2(0, 1)
			end_points[1] = Vector2(0, 4)
			grid[1][0] = 1
			grid[4][0] = 1
			
			start_points[2] = Vector2(2, 2)
			end_points[2] = Vector2(4, 4)
			grid[2][2] = 2
			grid[4][4] = 2
	
	queue_redraw()

func _draw():
	draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE)
	
	for i in range(GRID_SIZE + 1):
		var x = i * CELL_SIZE
		var y = i * CELL_SIZE
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color.GRAY, 1)
		draw_line(Vector2(0, y), Vector2(size.x, y), Color.GRAY, 1)
	
	for color in paths:
		draw_path(paths[color], colors[color])
	
	if current_path.size() > 1:
		draw_path(current_path, colors[current_color])
	
	for color in start_points:
		draw_point(start_points[color], colors[color], false)
		draw_point(end_points[color], colors[color], true)

func draw_path(path: Array, color: Color):
	if path.size() < 2:
		return
	
	for i in range(path.size() - 1):
		var start_pos = grid_to_pixel(path[i]) + Vector2(CELL_SIZE/2, CELL_SIZE/2)
		var end_pos = grid_to_pixel(path[i + 1]) + Vector2(CELL_SIZE/2, CELL_SIZE/2)
		draw_line(start_pos, end_pos, color, 8)

func draw_point(grid_pos: Vector2, color: Color, is_endpoint: bool = false):
	var pixel_pos = grid_to_pixel(grid_pos) + Vector2(CELL_SIZE/2, CELL_SIZE/2)
	var radius = 15 if is_endpoint else 10
	draw_circle(pixel_pos, radius, color)
	
	if is_endpoint:
		draw_circle(pixel_pos, radius - 3, Color.WHITE)
		draw_circle(pixel_pos, radius - 6, color)

func grid_to_pixel(grid_pos: Vector2) -> Vector2:
	return Vector2(grid_pos.x * CELL_SIZE, grid_pos.y * CELL_SIZE)

func pixel_to_grid(pixel_pos: Vector2) -> Vector2:
	return Vector2(int(pixel_pos.x / CELL_SIZE), int(pixel_pos.y / CELL_SIZE))

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_drawing(event.position)
			else:
				finish_drawing()
	elif event is InputEventMouseMotion:
		if is_drawing:
			continue_drawing(event.position)

func start_drawing(mouse_pos: Vector2):
	var grid_pos = pixel_to_grid(mouse_pos)
	
	if not is_valid_position(grid_pos):
		return
	
	if grid[int(grid_pos.y)][int(grid_pos.x)] == -2:
		return
	
	for color in start_points:
		if start_points[color] == grid_pos:
			is_drawing = true
			current_color = color
			current_path = [grid_pos]
			if color in paths:
				clear_path_from_grid(color)
			queue_redraw()
			return
	
	for color in paths:
		if is_position_in_path(grid_pos, paths[color]):
			is_drawing = true
			current_color = color
			var index = find_position_in_path(grid_pos, paths[color])
			if index != -1:
				current_path = []
				for i in range(index + 1):
					current_path.append(paths[color][i])
				clear_path_from_grid(color)
				update_grid_with_path(current_path, color)
				queue_redraw()
			return

func continue_drawing(mouse_pos: Vector2):
	if not is_drawing:
		return
	
	var grid_pos = pixel_to_grid(mouse_pos)
	
	if not is_valid_position(grid_pos):
		return
	
	if current_path.size() > 0 and current_path[-1] == grid_pos:
		return
	
	if grid[int(grid_pos.y)][int(grid_pos.x)] == -2:
		return
	
	if current_path.size() > 0:
		var last_pos = current_path[-1]
		var distance = abs(grid_pos.x - last_pos.x) + abs(grid_pos.y - last_pos.y)
		
		if distance == 1:
			if can_place_path(grid_pos, current_color):
				if current_path.size() > 1 and current_path[-2] == grid_pos:
					var removed_pos = current_path.pop_back()
					if removed_pos != start_points[current_color] and removed_pos != end_points[current_color]:
						grid[int(removed_pos.y)][int(removed_pos.x)] = -1
				else:
					current_path.append(grid_pos)
					grid[int(grid_pos.y)][int(grid_pos.x)] = current_color
				queue_redraw()

func finish_drawing():
	if not is_drawing:
		return
	
	is_drawing = false
	
	if current_path.size() > 1:
		paths[current_color] = current_path.duplicate()
		var end_pos = current_path[-1]
		if end_pos == end_points[current_color]:
			check_puzzle_completion()
	
	current_path.clear()
	current_color = -1
	queue_redraw()

func can_place_path(grid_pos: Vector2, color: int) -> bool:
	var x = int(grid_pos.x)
	var y = int(grid_pos.y)
	
	if grid[y][x] == -1:
		return true
	
	if grid_pos == end_points[color]:
		return true
	
	if grid[y][x] == color:
		return true
	
	return false

func clear_path_from_grid(color: int):
	if color in paths:
		for pos in paths[color]:
			var x = int(pos.x)
			var y = int(pos.y)
			if pos != start_points[color] and pos != end_points[color]:
				grid[y][x] = -1

func update_grid_with_path(path: Array, color: int):
	for pos in path:
		var x = int(pos.x)
		var y = int(pos.y)
		grid[y][x] = color

func is_valid_position(grid_pos: Vector2) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < GRID_SIZE and grid_pos.y >= 0 and grid_pos.y < GRID_SIZE

func is_position_in_path(pos: Vector2, path: Array) -> bool:
	for path_pos in path:
		if path_pos.x == pos.x and path_pos.y == pos.y:
			return true
	return false

func find_position_in_path(pos: Vector2, path: Array) -> int:
	for i in range(path.size()):
		if path[i].x == pos.x and path[i].y == pos.y:
			return i
	return -1

func check_puzzle_completion():
	for color in start_points:
		if not color in paths:
			return false
		var path = paths[color]
		if path.size() < 2 or path[-1] != end_points[color]:
			return false
	
	print("¡Puzzle completado!")
	show_completion_message()
	await get_tree().create_timer(1.5).timeout
	next_level()
	return true

func show_completion_message():
	print("¡Felicitaciones! Has completado el puzzle del nivel ", current_level)

func next_level():
	if current_level >= MAX_LEVEL:
		print("¡Todos los puzzles completados! Regresando al mundo principal...")
		await get_tree().create_timer(1.0).timeout
		get_tree().change_scene_to_file("res://Mundo/main_2.tscn")
	else:
		current_level += 1
		create_puzzle()
		print("Comenzando nivel ", current_level)

func _on_new_puzzle_pressed():
	create_puzzle()
