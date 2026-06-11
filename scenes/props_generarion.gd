extends TileMapLayer

@export var map_width: int = 200
@export var map_height: int = 200

# Ile maksymalnie dużych obiektów spróbować postawić na całej mapie
@export var max_trees: int = 150
@export var max_stones: int = 100

@onready var objects_layer: TileMapLayer = $"../Obiekty" 

func _ready() -> void:
	# Inicjalizacja generatora losowości
	randomize()
	
	# 1. Pobieramy ID dla każdego pliku graficznego na podstawie ich kolejności w TileSetie
	# Zazwyczaj pierwszy dodany plik ma ID 0, drugi 1, trzeci 2 itd.
	var id_trawy: int = tile_set.get_source_id(0)
	var id_drzewa: int = tile_set.get_source_id(1)
	var id_kamienia: int = tile_set.get_source_id(2)
	
	# Współrzędna kafelka wewnątrz każdego atlasu (jeśli to pojedyncze grafiki, zawsze (0,0))
	var tile_coords = Vector2i(0, 0)
	
	var half_width: int = int(map_width / 2)
	var half_height: int = int(map_height / 2)
	
	# 2. GENEROWANIE PODŁOŻA (Ziemia/Trawa)
	for x in range(-half_width, half_width):
		for y in range(-half_height, half_height):
			set_cell(Vector2i(x, y), id_trawy, tile_coords)
			
	# 3. LOSOWE STAWIANIE DUŻYCH DRZEW (4x4)
	var placed_trees: int = 0
	while placed_trees < max_trees:
		# Losujemy lewy górny róg obiektu (z marginesem, aby nie wyszedł poza mapę)
		var rx: int = randi_range(-half_width, half_width - 5)
		var ry: int = randi_range(-half_height, half_height - 5)
		
		if is_area_empty(rx, ry, 4, 4):
			# Wypełniamy obszar 4x4 kafelkami drzewa
			for x in range(4):
				for y in range(4):
					objects_layer.set_cell(Vector2i(rx + x, ry + y), id_drzewa, tile_coords)
			placed_trees += 1

	# 4. LOSOWE STAWIANIE DUŻYCH KAMIENI (3x3)
	var placed_stones: int = 0
	while placed_stones < max_stones:
		var rx: int = randi_range(-half_width, half_width - 4)
		var ry: int = randi_range(-half_height, half_height - 4)
		
		if is_area_empty(rx, ry, 3, 3):
			# Wypełniamy obszar 3x3 kafelkami kamienia
			for x in range(3):
				for y in range(3):
					objects_layer.set_cell(Vector2i(rx + x, ry + y), id_kamienia, tile_coords)
			placed_stones += 1

# Funkcja pomocnicza sprawdzająca, czy wybrany kwadrat na mapie obiektów jest pusty
func is_area_empty(start_x: int, start_y: int, width: int, height: int) -> bool:
	for x in range(width):
		for y in range(height):
			# get_cell_source_id zwraca -1, jeśli na danej kratce nic nie ma
			if objects_layer.get_cell_source_id(Vector2i(start_x + x, start_y + y)) != -1:
				return false # Obszar zajęty
	return true # Obszar wolny
