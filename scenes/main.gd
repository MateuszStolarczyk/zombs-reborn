extends Node2D

@onready var night: CanvasModulate = $Player/Camera2D/Night
@onready var anim_night: AnimationPlayer = $Player/Camera2D/Night/anim_night

# NOWE: Referencja do paska UI w CanvasLayer lokalnego gracza
@onready var time_ui: TextureRect = $Player/CanvasLayer/HUD/TimeCycleUI

var is_night: bool = false 
var game_timer: Timer # WYZNAKOWANE: Przeniesione tutaj, aby _process widział licznik

func _ready() -> void:
	night.color = Color.WHITE
	night.visible = true
	
	# Tworzymy dynamicznie licznik czasu (Timer)
	game_timer = Timer.new()
	add_child(game_timer)
	
	game_timer.wait_time = 30.0
	game_timer.one_shot = false
	game_timer.timeout.connect(_on_time_changed)
	game_timer.start()

# Funkcja wykonuje się w każdej klatce gry
func _process(_delta: float) -> void:
	if game_timer and time_ui and time_ui.material:
		# 1. Obliczamy ile sekund minęło w obecnej fazie (wartość od 0 do 30)
		var elapsed_seconds: float = game_timer.wait_time - game_timer.time_left
		
		# 2. Pełny cykl (dzień + noc) trwa dwa razy dłużej niż odliczanie timera (czyli 60 sekund)
		var total_cycle_duration: float = game_timer.wait_time * 2.0
		
		# 3. Wyliczamy postęp procentowy (od 0.0 do 0.5 dla dnia)
		var current_progress: float = elapsed_seconds / total_cycle_duration
		
		# 4. Jeśli trwa noc, przesuwamy grafikę o dodatkowe 0.5 (czyli o połowę obrazka)
		if is_night:
			current_progress += 0.5
			
		# 5. Przekazujemy wynik do shadera, co przesuwa obrazek idealnie w lewo
		time_ui.material.set_shader_parameter("progress", current_progress)

func _on_time_changed() -> void:
	is_night = !is_night 
	
	if is_night:
		anim_night.play("night")
		anim_night.seek(0.0, true)
	else:
		if anim_night.has_animation("day"):
			anim_night.play("day")
			anim_night.seek(0.0, true)
		else:
			anim_night.play_backwards("night")
