extends Node2D

@onready var night: CanvasModulate = $Player/Camera2D/Night
@onready var anim_night: AnimationPlayer = $Player/Camera2D/Night/anim_nihgt

# Używamy typu bool (true/false), co ułatwia przełączanie stanu dnia i nocy
var is_night: bool = false 

func _ready() -> void:
	# REFORMA: Zamiast ukrywać obiekt, resetujemy jego kolor do czystej bieli (dzień).
	# Dzięki temu eliminujemy mrugnięcie w pierwszej klatce gry.
	night.color = Color.WHITE
	night.visible = true
	
	# 1. Tworzymy dynamicznie licznik czasu (Timer)
	var timer = Timer.new()
	add_child(timer)
	
	# 2. Ustawiamy czas na 10 sekund (testowo)
	timer.wait_time = 10.0
	timer.one_shot = false # Timer ma działać w nieskończonej pętli
	
	# 3. Łączymy sygnał zakończenia odliczania z naszą funkcją zmiany czasu
	timer.timeout.connect(_on_time_changed)
	
	# 4. Uruchamiamy odliczanie
	timer.start()

# Ta funkcja uruchomi się automatycznie dokładnie co minutę
func _on_time_changed() -> void:
	# Odwracamy stan: jeśli był dzień (false), stanie się noc (true)
	is_night = !is_night 
	
	if is_night:
		# Naprawa pierwszego startu: Wymuszamy, aby animacja zaczęła odtwarzać się 
		# od samego początku (sekunda 0), gdzie kolor jest jeszcze biały.
		anim_night.play("night")
		anim_night.seek(0.0, true)
	else:
		# Jeśli masz osobną animację dnia rozjaśniającą ekran
		if anim_night.has_animation("day"):
			anim_night.play("day")
			anim_night.seek(0.0, true)
		else:
			# Odtwarzamy animację nocy w tył (rozjaśnianie)
			anim_night.play_backwards("night")
