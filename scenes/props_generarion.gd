extends TileMapLayer

@export var map_size: int = 200

@export var max_trees: int = 150
@export var max_stones: int = 100

@export var global_spacing_score: int = 10
@export var max_overlapping_pairs: int = 10

@export var tree_texture: Texture2D
@export var stone_texture: Texture2D
@export var max_offset: float = 0.3

var placed_trees: int = 0
var placed_stones: int = 0
var occupied_cells: Dictionary = {}

var obj_script: Script = preload("res://resource_object.gd")


func _ready() -> void:
	randomize()

	if tree_texture == null or stone_texture == null:
		push_error("Brak tekstur!")
		return

	var source_id: int = tile_set.get_source_id(0)
	var half_size: int = int(map_size / 2)

	# TŁO
	# Definiujemy pozycje 3 kafelków trawy w atlasie (rząd 0, kolumny 0, 1, 2)
	var grass_variants: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	
	for x in range(-half_size, half_size):
		for y in range(-half_size, half_size):
			# Losujemy jeden z trzech kafelków
			var random_grass = grass_variants.pick_random()
			set_cell(Vector2i(x, y), source_id, random_grass)

	# DRZEWA
	while placed_trees < max_trees:
		var rx: int = randi_range(-half_size, half_size)
		var ry: int = randi_range(-half_size, half_size)

		if is_grid_empty(rx, ry, 4, 4):
			mark_grid_occupied(rx, ry, 4, 4)
			spawn_object(tree_texture, rx, ry, 4)
			placed_trees += 1

	# KAMIENIE
	while placed_stones < max_stones:
		var rx: int = randi_range(-half_size, half_size)
		var ry: int = randi_range(-half_size, half_size)

		if is_grid_empty(rx, ry, 3, 3):
			mark_grid_occupied(rx, ry, 3, 3)
			spawn_object(stone_texture, rx, ry, 3)
			placed_stones += 1


func spawn_object(texture: Texture2D, gx: int, gy: int, base_size: int) -> void:
	var tile_size: Vector2 = Vector2(tile_set.tile_size)

	var body: StaticBody2D = StaticBody2D.new()
	body.set_script(obj_script)

	# grupy
	if texture == tree_texture:
		body.add_to_group("tree")
	elif texture == stone_texture:
		body.add_to_group("stone")

	# pozycja świata
	var center_offset: Vector2 = Vector2(
		tile_size.x * (base_size - 1) / 2.0,
		tile_size.y * (base_size - 1) / 2.0
	)

	var angle: float = randf() * TAU
	var distance: float = randf_range(0.0, max_offset)

	var random_offset: Vector2 = Vector2(cos(angle), sin(angle)) * distance * tile_size

	body.global_position = map_to_local(Vector2i(gx, gy)) + center_offset + random_offset

	# sprite
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2(
		(tile_size.x * base_size) / texture.get_width(),
		(tile_size.y * base_size) / texture.get_height()
	)
	body.add_child(sprite)

	# collision (NIE RUSZAMY W KNOCKBACKIE)
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: ConvexPolygonShape2D = ConvexPolygonShape2D.new()

	var half_w: float = (tile_size.x * (base_size - 0.4)) / 2.0
	var half_h: float = (tile_size.y * (base_size - 0.4)) / 2.0

	var bx: float = half_w * 0.3
	var by: float = half_h * 0.3

	shape.points = PackedVector2Array([
		Vector2(-half_w + bx, -half_h), Vector2(half_w - bx, -half_h),
		Vector2(half_w, -half_h + by), Vector2(half_w, half_h - by),
		Vector2(half_w - bx, half_h), Vector2(-half_w + bx, half_h),
		Vector2(-half_w, half_h - by), Vector2(-half_w, -half_h + by)
	])

	collision.shape = shape
	body.add_child(collision)

	add_child(body)


func is_grid_empty(x: int, y: int, w: int, h: int) -> bool:
	for i in range(w):
		for j in range(h):
			if occupied_cells.has(Vector2i(x + i, y + j)):
				return false
	return true


func mark_grid_occupied(x: int, y: int, w: int, h: int) -> void:
	for i in range(w):
		for j in range(h):
			occupied_cells[Vector2i(x + i, y + j)] = true
