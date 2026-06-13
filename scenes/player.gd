extends CharacterBody2D

@export var speed: float = 300.0

@onready var hand_pivot: Node2D = $HandPivot
@onready var second_pivot: Node2D = $HandPivot/SecondPivot
@onready var camera: Camera2D = $Camera2D  # Pobieramy referencję do kamery
@onready var anim_player: AnimationPlayer = $HandPivot/SecondPivot/Hands/AnimationPlayer

func _ready() -> void:
	# Sprawdzamy, czy ten komputer ma "władzę" nad tym obiektem gracza
	if is_multiplayer_authority():
		camera.enabled = true  # Włączamy kamerę TYLKO dla lokalnego gracza
		camera.make_current()   # Upewniamy się, że to ta kamera jest głównym widokem
	else:
		# Jeśli to kopia innego gracza z sieci, wyłączamy dla niego kamerę
		camera.enabled = false 
	# Jeśli ten gracz NIE jest sterowany przez nas (to inny gracz w sieci)
	if not is_multiplayer_authority():
		$CanvasLayer.hide() # Ukrywamy jego UI na naszym ekranie

func _physics_process(delta: float) -> void:
	# WARUNEK BEZPIECZEŃSTWA: 
	# Jeśli ten obiekt reprezentuje innego gracza w sieci, NIE przetwarzaj dla niego klawiatury i myszki!
	if not is_multiplayer_authority():
		return
	if Input.is_action_just_pressed("attack"):
		attack();
	if Input.is_action_pressed("attack"):
		attack()

	# --- Poniższy kod wykona się TYLKO na komputerze właściciela tej postaci ---

	# 1. Ruch
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()

	# 2. Obrót rąk
	hand_pivot.look_at(get_global_mouse_position())
func attack():
	anim_player.speed_scale = 2
	anim_player.play("attack")
