extends StaticBody2D

var visual: Node2D
var original_visual_pos: Vector2
var is_knockbacking: bool = false

func _ready() -> void:
	# tworzymy warstwę wizualną automatycznie (jeśli nie istnieje)
	if has_node("Visual"):
		visual = $Visual
	else:
		visual = Node2D.new()
		visual.name = "Visual"
		add_child(visual)

	# przenosimy wszystkie dzieci graficzne do Visual (sprite itd.)
	for child in get_children():
		if child != visual and child is Sprite2D:
			child.reparent(visual)

	original_visual_pos = visual.position


func hit(from_position: Vector2) -> void:
	if is_knockbacking:
		return

	is_knockbacking = true

	# kierunek OD gracza
	var dir: Vector2 = (global_position - from_position).normalized()

	var strength: float = 10.0
	var target: Vector2 = original_visual_pos + dir * strength

	var tween := create_tween()

	# 🔥 RUSZAMY TYLKO WIZUAL
	tween.tween_property(visual, "position", target, 0.08)
	tween.tween_property(visual, "position", original_visual_pos, 0.10)

	await tween.finished
	is_knockbacking = false
