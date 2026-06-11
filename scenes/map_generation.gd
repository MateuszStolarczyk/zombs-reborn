extends TileMapLayer

# Dokładne wymiary mapy
@export var map_size: int = 200

func _ready() -> void:
	var source_id = tile_set.get_source_id(0)
	var atlas_coords = Vector2i(0, 0)
	
	# Bezpieczne obliczenie połowy za pomocą int()
	var half_size: int = int(map_size / 2)
	
	# Generowanie mapy wycentrowanej na punkcie (0,0)
	for x in range(-half_size, half_size):
		for y in range(-half_size, half_size):
			set_cell(Vector2i(x, y), source_id, atlas_coords)
