extends Panel

@onready var stats: Node = $"../../../Stats"

@onready var a_wood: Label = $Round/VBoxContainer/FirstRow/Wood/Margin/HBox/AWood
@onready var a_stone: Label = $Round/VBoxContainer/FirstRow/Stone/Margin/HBox/AStone
@onready var a_gold: Label = $Round/VBoxContainer/SecRow/Gold/Margin/HBox/AGold
@onready var a_tokens: Label = $Round/VBoxContainer/SecRow/Tokens/Margin/HBox/ATokens
@onready var a_wave: Label = $Round/VBoxContainer/Wave/Margin/HBox/AWave


func _process(_delta: float) -> void:
	update_ui()


func update_ui() -> void:
	a_wood.text = format_number(stats.wood)
	a_stone.text = format_number(stats.stone)
	a_gold.text = format_number(stats.gold)
	a_tokens.text = format_number(stats.tokens)
	a_wave.text = str(stats.wave)


func format_number(value: float) -> String:
	if value < 1000.0:
		return str(int(value))

	var suffixes_kmbt := ["K", "M", "B", "T"]

	var num: float = value
	var index: int = 0

	while num >= 1000.0 and index < suffixes_kmbt.size():
		num /= 1000.0
		index += 1

	# K / M / B / T
	if index > 0 and index <= suffixes_kmbt.size():
		return _format_num(num) + suffixes_kmbt[index - 1]

	# AA system po T
	var aa_index := index - suffixes_kmbt.size()
	return _format_num(num) + _get_suffix(aa_index)


func _format_num(num: float) -> String:
	if num >= 100:
		return str(round(num))
	elif num >= 10:
		return str(snapped(num, 0.1)).rstrip("0").rstrip(".")
	else:
		return str(snapped(num, 0.01)).rstrip("0").rstrip(".")


func _get_suffix(index: int) -> String:
	var letters := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	var result := ""

	while index >= 0:
		result = letters[index % 26] + result
		index = int(index / 26.0) - 1

	return result
