extends Node2D

# Ścieżki do scen budynków
const WALL_SCENE = preload("res://buldings/tier1/wall-t1.tscn")
const TURRET_SCENE = preload("res://buldings/tier1/bomb-tower-t1.tscn")

@onready var tile_map_layer: TileMapLayer = $"../Map"
@onready var buildings_container: Node2D = $"."

var occupied_cells = {}
var current_build_mode = 0
var ghost_instance: Node2D = null

# Ustaw tutaj sumę wartości swoich warstw kolizji, które mają blokować budowanie
# (np. warstwa 2 = 2, warstwa 3 = 4, więc 2 + 4 = 6)
const PHYSICS_COLLISION_MASK = 0xFFFFFFFF 

func _process(delta: float) -> void:
	if current_build_mode != 0 and ghost_instance != null:
		update_ghost(delta)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1: change_mode(1)
		if event.keycode == KEY_2: change_mode(2)
	
	if event.is_action_pressed("mouse_left_click") and current_build_mode != 0:
		try_to_build()

func change_mode(mode: int) -> void:
	current_build_mode = mode
	if ghost_instance: ghost_instance.queue_free()
	
	if mode == 1: ghost_instance = WALL_SCENE.instantiate()
	elif mode == 2: ghost_instance = TURRET_SCENE.instantiate()
	
	# Wyłączamy kolizje ducha, aby sam ze sobą nie kolidował
	set_collision_off(ghost_instance)
	buildings_container.add_child(ghost_instance)

# Rekurencyjne wyłączanie kolizji w duchu
func set_collision_off(node: Node) -> void:
	if node is CollisionObject2D:
		node.set_collision_layer_value(1, false)
		node.set_collision_mask_value(1, false)
	for child in node.get_children():
		set_collision_off(child)

func update_ghost(delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var cell_coords = tile_map_layer.local_to_map(tile_map_layer.to_local(mouse_pos))
	
	# Oblicz docelową pozycję (środek kafelka)
	var local_pos = tile_map_layer.map_to_local(cell_coords)
	if current_build_mode == 2:
		var tile_size = tile_map_layer.tile_set.tile_size
		local_pos += Vector2(tile_size.x / 2, tile_size.y / 2)
	
	var target_pos = tile_map_layer.to_global(local_pos)
	
	# Płynny ruch ducha
	ghost_instance.global_position = ghost_instance.global_position.lerp(target_pos, delta * 15.0)
	
	# Walidacja: Grid + Fizyka
	var grid_occupied = false
	for cell in get_building_cells(cell_coords, current_build_mode):
		if occupied_cells.has(cell):
			grid_occupied = true
			break
			
	var physics_occupied = is_space_occupied_by_physics(target_pos, current_build_mode)
	
	# Zmiana koloru ducha
	if !grid_occupied and !physics_occupied:
		ghost_instance.modulate = Color(0, 1, 0, 0.5) # Zielony
	else:
		ghost_instance.modulate = Color(1, 0, 0, 0.5) # Czerwony

func is_space_occupied_by_physics(global_pos: Vector2, mode: int) -> bool:
	var space_state = get_world_2d().direct_space_state
	var params = PhysicsShapeQueryParameters2D.new()
	
	var shape = RectangleShape2D.new()
	# Rozmiar kształtu (dla 1x1: 64x64, dla 2x2: 128x128) - dopasuj do rozmiaru kafelka
	var tile_size = tile_map_layer.tile_set.tile_size
	shape.size = Vector2(tile_size.x, tile_size.y) if mode == 1 else Vector2(tile_size.x * 2, tile_size.y * 2)
	
	params.shape = shape
	params.transform = Transform2D(0, global_pos)
	params.collision_mask = PHYSICS_COLLISION_MASK 
	
	var result = space_state.intersect_shape(params)
	return result.size() > 0

func try_to_build() -> void:
	var mouse_pos = get_global_mouse_position()
	var cell_coords = tile_map_layer.local_to_map(tile_map_layer.to_local(mouse_pos))
	
	# Oblicz pozycję budowy
	var local_pos = tile_map_layer.map_to_local(cell_coords)
	if current_build_mode == 2:
		local_pos += Vector2(tile_map_layer.tile_set.tile_size.x / 2, tile_map_layer.tile_set.tile_size.y / 2)
	var target_pos = tile_map_layer.to_global(local_pos)
	
	# Ostateczne sprawdzenie przed postawieniem
	var cells_to_occupy = get_building_cells(cell_coords, current_build_mode)
	for cell in cells_to_occupy:
		if occupied_cells.has(cell): return
	if is_space_occupied_by_physics(target_pos, current_build_mode): return
	
	# Instancjonowanie
	var new_building = (WALL_SCENE if current_build_mode == 1 else TURRET_SCENE).instantiate()
	new_building.global_position = target_pos
	buildings_container.add_child(new_building)
	
	# Blokowanie kafelków
	for cell in cells_to_occupy:
		occupied_cells[cell] = true

func get_building_cells(start_cell: Vector2i, mode: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if mode == 1:
		cells.append(start_cell)
	elif mode == 2:
		cells.append(start_cell)
		cells.append(start_cell + Vector2i(1, 0))
		cells.append(start_cell + Vector2i(0, 1))
		cells.append(start_cell + Vector2i(1, 1))
	return cells
