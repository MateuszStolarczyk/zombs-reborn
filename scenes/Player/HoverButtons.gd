extends Node

# Definiujemy dostępne strony w menu rozwijanym
enum TooltipSide { LEFT, RIGHT }

@export_group("Ustawienia Przyciskow")
@export var buttons: Array[Control] = []
@export var tooltip_texts: Array[String] = []

@export_group("Ustawienia Chmurki")
@export var tooltip_panel: PanelContainer 
@export var label_path: String = "MarginContainer/Label"
# Nowy export! Pojawi się w Inspektorze jako lista rozwijana
@export var tooltip_side: TooltipSide = TooltipSide.LEFT
@export var gap_pixels: float = 10.0 # Odstęp chmurki od przycisku

var active_tweens: Dictionary = {}
var chmurka_label: Label

func _ready() -> void:
	if tooltip_panel:
		tooltip_panel.hide()
		chmurka_label = tooltip_panel.get_node_or_null(label_path) as Label

	for i in range(buttons.size()):
		var btn = buttons[i]
		if not btn: 
			continue
		
		var text_for_this_button = tooltip_texts[i] if i < tooltip_texts.size() else "Brak opisu"
		
		btn.mouse_entered.connect(_on_button_hover.bind(btn, true, text_for_this_button))
		btn.mouse_exited.connect(_on_button_hover.bind(btn, false, ""))
		
		var img = btn.get_node_or_null("Margin/IMG")
		if img:
			img.modulate = Color("ffffffa0")

func _on_button_hover(btn: Control, is_hover: bool, text: String) -> void:
	# 1. Animacja ikony
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
	
	# 2. Obsługa chmurki
	if not tooltip_panel or not chmurka_label:
		return
		
	if is_hover:
		chmurka_label.text = text
		tooltip_panel.show()
		
		# Czekamy 1 klatkę na przeskalowanie chmurki
		await get_tree().process_frame
		
		# Wyliczamy pozycję X w zależności od wybranej strony
		var target_x: float = 0.0
		
		if tooltip_side == TooltipSide.LEFT:
			# Pozycja po lewej: początek przycisku - szerokość chmurki - odstęp
			target_x = btn.global_position.x - tooltip_panel.size.x - gap_pixels
		else:
			# Pozycja po prawej: początek przycisku + szerokość przycisku + odstęp
			target_x = btn.global_position.x + btn.size.x + gap_pixels
			
		# Wyśrodkowanie w pionie (zostaje bez zmian)
		var target_y = btn.global_position.y + (btn.size.y / 2) - (tooltip_panel.size.y / 2)
		
		tooltip_panel.global_position = Vector2(target_x, target_y)
	else:
		tooltip_panel.hide()
