extends PanelContainer

func _ready() -> void:
	# Ustawiamy wysoki priorytet. Dzięki temu ten skrypt wykona się PO tym,
	# jak skrypt-manager z innej sceny ustawi pozycję chmurki.
	process_priority = 100

func _process(_delta: float) -> void:
	# Teraz na pewno zaokrąglamy pozycję jako ostatni!
	global_position = global_position.round()
