extends TileMapLayer

@export var map_size: int = 200

# GŁÓWNE LIMITY ILOŚCIOWE
@export var max_trees: int = 150
@export var max_stones: int = 100

# JEDEN EXPORT DLA ODSTĘPU (10 = standard, mniejsze wartości np. 5 = obiekty są dalej od siebie)
@export var global_spacing_score: int = 10

# MAKSYMALNA ILOŚĆ ZŁĄCZONYCH PAR
@export var max_overlapping_pairs: int = 10

@export var tree_texture: Texture2D
@export var stone_texture: Texture2D
@export var max_offset: float = 0.3

# Globalne liczniki obiektów
var placed_trees: int = 0
var placed_stones: int = 0
var occupied_cells: Dictionary = {}

func _ready() -> void:
	randomize()
	
	if not tree_texture or not stone_texture:
		push_error("BŁĄD: Brak tekstur w Inspektorze!")
		return
	
	var source_id = tile_set.get_source_id(0)
	var half_size: int = int(map_size / 2)
	
	# 1. RYSOWANIE PODŁOŻA (TRAWA)
	for x in range(-half_size, half_size):
		for y in range(-half_size, half_size):
			set_cell(Vector2i(x, y), source_id, Vector2i(0, 0))
			
	var max_attempts: int = 4000
	
	# Wyliczenie bufora odległości z ogólnej gęstości
	var spacing_buffer: int = max(0, 10 - global_spacing_score)
	
	# 2. GENEROWANIE ZŁĄCZONYCH PAR
	var placed_pairs: int = 0
	var pair_attempts: int = 0
	
	while placed_pairs < max_overlapping_pairs and pair_attempts < 1000:
		pair_attempts += 1
		var pair_type = randi() % 3 # 0: Drzewo+Kamień, 1: Drzewo+Drzewo, 2: Kamień+Kamień
		
		# Ustalenie rozmiarów bazowych dla pary (Drzewo = 4, Kamień = 3)
		var s1: int = 4 if (pair_type == 0 or pair_type == 1) else 3
		var s2: int = 3 if (pair_type == 0 or pair_type == 2) else 4
		var tex1 = tree_texture if (pair_type == 0 or pair_type == 1) else stone_texture
		var tex2 = stone_texture if (pair_type == 0 or pair_type == 2) else tree_texture
		
		var rx: int = randi_range(-half_size, half_size - 10)
		var ry: int = randi_range(-half_size, half_size - 10)
		
		# Pozycja drugiego obiektu przesunięta na krawędź pierwszego
		var o2_x = rx + s1 - 1
		var o2_y = ry + 1
		
		# Sprawdzenie czy cała strefa dla pary jest wolna
		if is_grid_empty(rx, ry, s1, s1, occupied_cells) and is_grid_empty(o2_x, o2_y, s2, s2, occupied_cells):
			mark_grid_occupied(rx, ry, s1, s1, occupied_cells)
			mark_grid_occupied(o2_x, o2_y, s2, s2, occupied_cells)
			
			spawn_single_object(tex1, rx, ry, s1)
			spawn_single_object(tex2, o2_x, o2_y, s2)
			
			if pair_type == 0:
				placed_trees += 1
				placed_stones += 1
			elif pair_type == 1:
				placed_trees += 2
			else:
				placed_stones += 2
			
			placed_pairs += 1

	# 3. GENEROWANIE POZOSTAŁYCH SAMOTNYCH DRZEW
	var tree_attempts: int = 0
	var tree_size_buffered: int = 4 + spacing_buffer
	
	while placed_trees < max_trees and tree_attempts < max_attempts:
		tree_attempts += 1
		var rx: int = randi_range(-half_size, half_size - tree_size_buffered - 1)
		var ry: int = randi_range(-half_size, half_size - tree_size_buffered - 1)
		
		if is_grid_empty(rx, ry, tree_size_buffered, tree_size_buffered, occupied_cells):
			mark_grid_occupied(rx, ry, tree_size_buffered, tree_size_buffered, occupied_cells)
			spawn_single_object(tree_texture, rx, ry, 4)
			placed_trees += 1

	# 4. GENEROWANIE POZOSTAŁYCH SAMOTNYCH KAMIENI
	var stone_attempts: int = 0
	var stone_size_buffered: int = 3 + spacing_buffer
	
	while placed_stones < max_stones and stone_attempts < max_attempts:
		stone_attempts += 1
		var rx: int = randi_range(-half_size, half_size - stone_size_buffered - 1)
		var ry: int = randi_range(-half_size, half_size - stone_size_buffered - 1)
		
		if is_grid_empty(rx, ry, stone_size_buffered, stone_size_buffered, occupied_cells):
			mark_grid_occupied(rx, ry, stone_size_buffered, stone_size_buffered, occupied_cells)
			spawn_single_object(stone_texture, rx, ry, 3)
			placed_stones += 1

# Uniwersalna funkcja tworząca pojedynczy obiekt w świecie gry
func spawn_single_object(texture: Texture2D, gx: int, gy: int, base_size: int) -> void:
	# POPRAWKA: Jawne rzutowanie rozmiaru kafelka na Vector2, żeby kompilator znał typy matematyczne
	var t_size: Vector2 = Vector2(tile_set.tile_size)
	var body = StaticBody2D.new()
	
	# Centrowanie pozycji i dodanie losowego kołowego odchyłu 360°
	var center_offset := Vector2(t_size.x * (base_size - 1) / 2.0, t_size.y * (base_size - 1) / 2.0)
	var angle: float = randf() * TAU
	var distance: float = randf_range(0, max_offset)
	
	# POPRAWKA: Wymuszenie stałego typu Vector2 dla bezpiecznej kalkulacji offsetu
	var random_offset: Vector2 = Vector2(cos(angle), sin(angle)) * distance * t_size
	
	body.position = map_to_local(Vector2i(gx, gy)) + center_offset + random_offset
	
	# Skalowanie grafiki sprite
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2((t_size.x * base_size) / texture.get_width(), (t_size.y * base_size) / texture.get_height())
	body.add_child(sprite)
	
	# Tworzenie bezpiecznej, ściętej o 15% kolizji (rozmiar mniejszy o 0.4 kafelka od tekstury)
	var collision = CollisionShape2D.new()
	var shape = ConvexPolygonShape2D.new()
	var half_w: float = (t_size.x * (base_size - 0.4)) / 2.0
	var half_h: float = (t_size.y * (base_size - 0.4)) / 2.0
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

# Funkcje obsługi logicznej siatki mapy
func is_grid_empty(start_x: int, start_y: int, width: int, height: int, occupied: Dictionary) -> bool:
	for x in range(width):
		for y in range(height):
			if occupied.has(Vector2i(start_x + x, start_y + y)): 
				return false
	return true

func mark_grid_occupied(start_x: int, start_y: int, width: int, height: int, occupied: Dictionary) -> void:
	for x in range(width):
		for y in range(height): 
			occupied[Vector2i(start_x + x, start_y + y)] = true
