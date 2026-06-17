extends CharacterBody2D

@onready var stats = $Stats

@export var speed: float = 300.0

@onready var hand_pivot: Node2D = $HandPivot
@onready var second_pivot: Node2D = $HandPivot/SecondPivot
@onready var camera: Camera2D = $Camera2D
@onready var anim_player: AnimationPlayer = $HandPivot/SecondPivot/Hands/AnimationPlayer

@onready var ray_1: RayCast2D = $HandPivot/Ray1
@onready var ray_2: RayCast2D = $HandPivot/Ray2
@onready var ray_3: RayCast2D = $HandPivot/Ray3

var is_attacking := false

func _ready() -> void:
	if is_multiplayer_authority():
		camera.enabled = true
		camera.make_current()
	else:
		camera.enabled = false

	if not is_multiplayer_authority():
		$CanvasLayer.hide()


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	if Input.is_action_pressed("attack") and not is_attacking:
		attack()

	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	velocity = direction * speed
	move_and_slide()

	hand_pivot.look_at(get_global_mouse_position())


func attack():
	is_attacking = true

	anim_player.speed_scale = 2
	anim_player.play("attack")

	await anim_player.animation_finished

	collect_resources()

	is_attacking = false


func collect_resources():
	var hit_objects := {}

	var rays = [ray_1, ray_2, ray_3]

	for ray in rays:
		if ray.is_colliding():
			var collider = ray.get_collider()
			hit_objects[collider] = true

	for collider in hit_objects.keys():

		# 🔥 knockback / “odrzut”
		if collider.has_method("hit"):
			collider.hit(global_position)

		# 🌲 zasoby
		if collider.is_in_group("tree"):
			stats.wood += 1
			print("Drewno: ", stats.wood)

		elif collider.is_in_group("stone"):
			stats.stone += 1
			print("Kamień: ", stats.stone)
