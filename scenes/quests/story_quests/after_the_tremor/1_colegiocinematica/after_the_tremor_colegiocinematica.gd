# CinematicController.gd - Cinemática completa + movimiento personajes + hole en TileMap + transición a minijuego/escena
extends Node2D

# --- Recursos / escenas ---
@export var dialogue_resource: Resource
@export var start_title: String = ""
@export var minigame_scene: PackedScene

# --- Nodos principales (setear en inspector) ---
@export var camera_path: NodePath
@export var anim_player_path: NodePath
@export var dialogue_label_path: NodePath
@export var fade_rect_path: NodePath
@export var ambience_path: NodePath
@export var sfx_path: NodePath
@export var bryan_path: NodePath
@export var charlie_path: NodePath

# --- TileMap (Piso) para abrir hueco ---
@export var piso_path: NodePath
@export var hole_rect_start: Vector2i = Vector2i(1, 5)
@export var hole_rect_end: Vector2i = Vector2i(5, 11)

# --- Waypoints (posiciones) para mover personajes entre diálogos ---
@export var entry_point_path: NodePath        # donde entran (por ejemplo puerta)
@export var inside_point_path: NodePath       # punto dentro del colegio
@export var lever_point_path: NodePath        # posición cerca de la palanca
@export var fall_offset_y: float = 380.0      # cuánto baja Bryan al caer (tween fallback)

# --- nombres de anims (opcional) ---
@export var lever_anim_name: String = "lever_pull"
@export var floor_open_anim_name: String = "floor_open"
@export var camera_intro_anim: String = "camera_intro"
@export var bryan_fall_anim: String = "bryan_fall"

# --- onready ---
@onready var camera = get_node_or_null(camera_path) as Camera2D
@onready var anim = get_node_or_null(anim_player_path) as AnimationPlayer
@onready var dlg_label = get_node_or_null(dialogue_label_path) as RichTextLabel
@onready var fade_rect = get_node_or_null(fade_rect_path) as ColorRect
@onready var ambience = get_node_or_null(ambience_path) as AudioStreamPlayer
@onready var sfx = get_node_or_null(sfx_path) as AudioStreamPlayer
@onready var bryan = get_node_or_null(bryan_path)
@onready var charlie = get_node_or_null(charlie_path)

# optional waypoints
@onready var entry_point = get_node_or_null(entry_point_path) as Node2D
@onready var inside_point = get_node_or_null(inside_point_path) as Node2D
@onready var lever_point = get_node_or_null(lever_point_path) as Node2D

# --- guardado de tiles para restore (por si lo necesitas) ---
var _saved_tiles: Dictionary = {}

var cinematic_active: bool = true

func _ready() -> void:
	if not dialogue_resource:
		push_error("Asignar dialogue_resource (after_the_tremor_stealth.dialogue) en el inspector.")
		return
	if dlg_label:
		dlg_label.visible = false
	if fade_rect:
		fade_rect.color.a = 1.0
	_run_cinematic()

# ---------------- TileMap helpers ----------------
func _get_piso_tilemap() -> TileMap:
	if piso_path == NodePath(""):
		return null
	var node = get_node_or_null(piso_path)
	if node and node is TileMap:
		return node
	return null

func _tilemap_get_cell(tilemap: TileMap, cell: Vector2i) -> int:
	if tilemap == null:
		return -1
	if tilemap.has_method("get_cellv"):
		return tilemap.get_cellv(cell)
	elif tilemap.has_method("get_cell"):
		return tilemap.get_cell(0, cell)
	else:
		return -1

func _tilemap_set_cell(tilemap: TileMap, cell: Vector2i, tile_id: int) -> void:
	if tilemap == null:
		return
	if tilemap.has_method("set_cellv"):
		tilemap.set_cellv(cell, tile_id)
	elif tilemap.has_method("set_cell"):
		tilemap.set_cell(0, cell, tile_id)

func _clear_tilemap_rect_and_save(tilemap: TileMap, start: Vector2i, end: Vector2i) -> void:
	if tilemap == null:
		return
	_saved_tiles.clear()
	var min_x = min(start.x, end.x)
	var max_x = max(start.x, end.x)
	var min_y = min(start.y, end.y)
	var max_y = max(start.y, end.y)
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var cell = Vector2i(x, y)
			var original = _tilemap_get_cell(tilemap, cell)
			_saved_tiles[cell] = original
			_tilemap_set_cell(tilemap, cell, -1)

func _restore_tilemap_from_saved(tilemap: TileMap) -> void:
	if tilemap == null:
		return
	for key in _saved_tiles.keys():
		var cell = key as Vector2i
		var tileid = _saved_tiles[key]
		_tilemap_set_cell(tilemap, cell, tileid)
	_saved_tiles.clear()

# ---------------- diálogo + typewriter compatibles ----------------
func _extract_text_from_line(line) -> String:
	if line == null:
		return ""
	var candidate_names = ["text", "raw_text", "line", "content", "dialogue"]
	if typeof(line) == TYPE_OBJECT:
		if line.has_method("get"):
			for name in candidate_names:
				var val = line.get(name) if line.has_method("get") else null
				if val != null and str(val) != "":
					return str(val)
	if typeof(line) == TYPE_DICTIONARY:
		for k in line.keys():
			return str(line[k])
	return str(line)

func _typewriter_show(text: String, speed: float = 0.02) -> void:
	if not dlg_label:
		await get_tree().create_timer(0.3).timeout
		return
	dlg_label.visible = true
	# compatibilidad RichTextLabel
	if dlg_label.has_method("append_bbcode") and dlg_label.has_method("clear"):
		if dlg_label.has_property("bbcode_enabled"):
			dlg_label.bbcode_enabled = true
		for i in range(text.length()):
			var sub = text.substr(0, i + 1)
			dlg_label.clear()
			dlg_label.append_bbcode(sub)
			await get_tree().create_timer(speed).timeout
		await get_tree().create_timer(0.35).timeout
		return
	if dlg_label.has_method("set_bbcode"):
		for i in range(text.length()):
			dlg_label.set_bbcode(text.substr(0, i + 1))
			await get_tree().create_timer(speed).timeout
		await get_tree().create_timer(0.35).timeout
		return
	if dlg_label.has_method("set_text"):
		for i in range(text.length()):
			dlg_label.set_text(text.substr(0, i + 1))
			await get_tree().create_timer(speed).timeout
		await get_tree().create_timer(0.35).timeout
		return
	await get_tree().create_timer(max(0.35, text.length() * speed)).timeout

# ---------------- utilidades movimiento personajes ----------------
# mueve un personaje a una posición con tween y cambia animación si existe AnimatedSprite2D o AnimationPlayer
func _move_character_to(node: Node, target: Vector2, duration: float = 0.8) -> void:
	if node == null:
		await get_tree().create_timer(duration).timeout
		return
	# intentar poner animación "walk"
	if node.has_node("AnimatedSprite2D"):
		var spr = node.get_node("AnimatedSprite2D")
		if spr and spr.has_method("play"):
			spr.play("walk")
	elif node.has_node("AnimationPlayer"):
		var ap = node.get_node("AnimationPlayer")
		if ap and ap.has_animation("walk"):
			ap.play("walk")
	# tween del position
	var tw = create_tween()
	tw.tween_property(node, "position", target, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	# volver a idle/stop anim
	if node.has_node("AnimatedSprite2D"):
		var spr2 = node.get_node("AnimatedSprite2D")
		if spr2 and spr2.has_method("play"):
			spr2.play("idle")
	elif node.has_node("AnimationPlayer"):
		var ap2 = node.get_node("AnimationPlayer")
		if ap2 and ap2.has_animation("idle"):
			ap2.play("idle")

# ---------------- palanca y abrir piso (reutiliza TileMap) ----------------
func _play_lever() -> void:
	if anim and anim.has_animation(lever_anim_name):
		anim.play(lever_anim_name)
		return
	var lever = get_node_or_null("Lever")
	if lever:
		var start_deg = lever.rotation_degrees
		var target_deg = start_deg - 25.0
		var tw = create_tween()
		tw.tween_property(lever, "rotation_degrees", target_deg, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tw.finished

func _open_floor() -> void:
	if anim and anim.has_animation(floor_open_anim_name):
		anim.play(floor_open_anim_name)
		return
	var piso = _get_piso_tilemap()
	if piso:
		_clear_tilemap_rect_and_save(piso, hole_rect_start, hole_rect_end)
		await get_tree().create_timer(0.12).timeout
		return
	var floortrap = get_node_or_null("FloorTrap")
	if floortrap:
		var target_y = floortrap.position.y + 40
		var tw = create_tween()
		tw.tween_property(floortrap, "position:y", target_y, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tw.finished
		if floortrap.has_node("CollisionShape2D"):
			var cs = floortrap.get_node("CollisionShape2D")
			if cs and cs.has_method("set_deferred"):
				cs.set_deferred("disabled", true)

# ---------------- flujo principal (cinemática) ----------------
func _disable_player_control() -> void:
	for p in [bryan, charlie]:
		if p == null:
			continue
		if p.has_method("set_physics_process"):
			p.set_physics_process(false)
		if p.has_method("set_process"):
			p.set_process(false)

func _enable_player_control() -> void:
	for p in [bryan, charlie]:
		if p == null:
			continue
		if p.has_method("set_physics_process"):
			p.set_physics_process(true)
		if p.has_method("set_process"):
			p.set_process(true)

func _run_cinematic() -> void:
	_disable_player_control()
	if ambience:
		ambience.play()


	# cámara intro
	if anim and anim.has_animation(camera_intro_anim):
		anim.play(camera_intro_anim)

	# Si hay entry_point, mover a entry y luego diálogo; si no, solo diálogo
	if entry_point and charlie:
		await _move_character_to(charlie, entry_point.global_position, 1.0)
	if entry_point and bryan:
		await _move_character_to(bryan, entry_point.global_position + Vector2(-16,0), 1.0)

	# diálogo inicial -- usamos 0 como enum seguro para MutationBehaviour.Wait
	var next_title = start_title
	while true:
		var line = await dialogue_resource.get_next_dialogue_line(next_title, [], 0)
		if line == null:
			break
		var txt = _extract_text_from_line(line)
		await _typewriter_show(txt, 0.02)

	# mover adentro si hay inside_point
	if inside_point:
		if charlie:
			await _move_character_to(charlie, inside_point.global_position, 0.8)
		if bryan:
			await _move_character_to(bryan, inside_point.global_position + Vector2(-12,0), 0.9)

	# continuar diálogo hasta llegar a la parte de la palanca
	while true:
		var line2 = await dialogue_resource.get_next_dialogue_line("", [], 0)
		if line2 == null:
			break
		var txt2 = _extract_text_from_line(line2)
		await _typewriter_show(txt2, 0.02)
		# si queremos hacer que en cierto texto se detenga y se acerquen a la palanca,
		# asumimos que el manager avanza en orden; después de ciertas líneas seguimos.

	# acercarse a la palanca si existe lever_point
	if lever_point:
		if charlie:
			await _move_character_to(charlie, lever_point.global_position, 0.6)
		if bryan:
			await _move_character_to(bryan, lever_point.global_position + Vector2(-10,0), 0.65)

	# palanca y abrir suelo
	await _play_lever()
	if sfx:
		sfx.play()
	await get_tree().create_timer(0.15).timeout
	await _open_floor()

	# Bryan cae (anim o tween)
	if anim and anim.has_animation(bryan_fall_anim):
		anim.play(bryan_fall_anim)
	else:
		if bryan:
			var twf = create_tween()
			twf.tween_property(bryan, "position:y", bryan.position.y + fall_offset_y, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			await twf.finished

	if sfx:
		sfx.play()
	await get_tree().create_timer(0.6).timeout

	# diálogo final (si hay más)
	while true:
		var line3 = await dialogue_resource.get_next_dialogue_line("", [], 0)
		if line3 == null:
			break
		var txt3 = _extract_text_from_line(line3)
		await _typewriter_show(txt3, 0.02)


	if ambience:
		ambience.stop()
	cinematic_active = false
	_enable_player_control()

	# NOTA: las tiles se guardaron en _saved_tiles; restaurar si hace falta con _restore_tilemap_from_saved()
	_start_next_scene_or_minigame()

func _start_next_scene_or_minigame() -> void:
	if minigame_scene:
		var inst = minigame_scene.instantiate()
		get_tree().root.add_child(inst)
		return
	# support template 'next_scene' prop si existe
	var props := []
	for p in get_property_list():
		props.append(p.name)
	if "next_scene" in props:
		var path = str(get("next_scene"))
		if path != "":
			get_tree().change_scene_to_file(path)
			return
	# fallback
	if has_node("/root/GameController"):
		get_node("/root/GameController").call_deferred("on_cinematic_finished")
