extends Node

enum TooltipSide { LEFT, RIGHT }

@export_group("Ustawienia Przyciskow")
@export var buttons: Array[Control] = []
# Zostawiamy, bo masz już ładnie ustawione Left/Right w Inspektorze!
@export var tooltip_sides: Array[TooltipSide] = [] 

@export_group("Teksty - Prosty Tooltip (Pierwsze 3)")
@export var simple_texts: Array[String] = []

@export_group("Teksty - Zaawansowany Tooltip (Reszta)")
@export var adv_names: Array[String] = []
@export var adv_types: Array[String] = []
@export var adv_descs: Array[String] = []
@export var adv_costs: Array[String] = []

@export_group("Wezly Chmurek")
@export var simple_panel: PanelContainer 
@export var simple_label_path: String = "MarginContainer/Label"

@export var advanced_panel: PanelContainer 
@export var adv_name_path: String = "MarginContainer/VBox/Nazwa"
@export var adv_type_path: String = "MarginContainer/VBox/Rodzaj"
@export var adv_desc_path: String = "MarginContainer/VBox/Opis"
@export var adv_cost_path: String = "MarginContainer/VBox/Cena"

@export_group("Inne")
@export var gap_pixels: float = 10.0

var active_tweens: Dictionary = {}

var lbl_simple: Label
var lbl_adv_name: Label
var lbl_adv_type: Label
var lbl_adv_desc: Label
var lbl_adv_cost: Label

func _ready() -> void:
	if simple_panel: simple_panel.hide()
	if advanced_panel: advanced_panel.hide()
	
	if simple_panel:
		lbl_simple = simple_panel.get_node_or_null(simple_label_path) as Label
	if advanced_panel:
		lbl_adv_name = advanced_panel.get_node_or_null(adv_name_path) as Label
		lbl_adv_type = advanced_panel.get_node_or_null(adv_type_path) as Label
		lbl_adv_desc = advanced_panel.get_node_or_null(adv_desc_path) as Label
		lbl_adv_cost = advanced_panel.get_node_or_null(adv_cost_path) as Label

	for i in range(buttons.size()):
		var btn = buttons[i]
		if not btn: continue
		
		btn.mouse_entered.connect(_on_button_hover.bind(i, true))
		btn.mouse_exited.connect(_on_button_hover.bind(i, false))
		
		var img = btn.get_node_or_null("Margin/IMG")
		if img:
			img.modulate = Color("ffffffa0")

func _on_button_hover(index: int, is_hover: bool) -> void:
	if index >= buttons.size(): return
	var btn = buttons[index]
	if not btn: return
	
	# 1. Animacja przezroczystości ikony
	var img = btn.get_node_or_null("Margin/IMG")
	if img:
		if active_tweens.has(btn) and active_tweens[btn].is_running():
			active_tweens[btn].kill()
		var target_color = Color("ffffff") if is_hover else Color("ffffffa0")
		var tween = create_tween()
		active_tweens[btn] = tween
		tween.tween_property(img, "modulate", target_color, 0.15)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_OUT)
	
	# 2. Ukrywanie paneli po zejściu myszki
	if not is_hover:
		if simple_panel: simple_panel.hide()
		if advanced_panel: advanced_panel.hide()
		return

	var active_panel: PanelContainer = null
	var side = tooltip_sides[index] if index < tooltip_sides.size() else TooltipSide.LEFT
	
	# 3. Sztywny podział logiczny na podstawie numeru przycisku (index)
	if index < 3:
		# Przyciski 0, 1, 2 -> Prosta chmurka
		if not simple_panel or not lbl_simple: return
		lbl_simple.text = simple_texts[index] if index < simple_texts.size() else "Brak opisu"
		active_panel = simple_panel
		if advanced_panel: advanced_panel.hide()
	else:
		# Przyciski 3, 4, itd. -> Zaawansowana chmurka
		if not advanced_panel: return
		
		# Odejmujemy 3, żeby przycisk nr 3 brał dane z indeksu 0 w tabelach tekstowych
		var adv_index = index - 3 
		
		if lbl_adv_name: lbl_adv_name.text = adv_names[adv_index] if adv_index < adv_names.size() else "Nazwa"
		if lbl_adv_type: lbl_adv_type.text = adv_types[adv_index] if adv_index < adv_types.size() else "Typ"
		if lbl_adv_desc: lbl_adv_desc.text = adv_descs[adv_index] if adv_index < adv_descs.size() else "Opis"
		if lbl_adv_cost: lbl_adv_cost.text = adv_costs[adv_index] if adv_index < adv_costs.size() else "Koszt"
		active_panel = advanced_panel
		if simple_panel: simple_panel.hide()

	# 4. Automatyczne kurczenie chmurki, wyświetlanie i pozycjonowanie
	active_panel.size = Vector2.ZERO
	active_panel.show()
	
	await get_tree().process_frame
	
	var target_x: float = 0.0
	if side == TooltipSide.LEFT:
		target_x = btn.global_position.x - active_panel.size.x - gap_pixels
	else:
		target_x = btn.global_position.x + btn.size.x + gap_pixels
		
	var target_y = btn.global_position.y + (btn.size.y / 2) - (active_panel.size.y / 2)
	active_panel.global_position = Vector2(target_x, target_y)
