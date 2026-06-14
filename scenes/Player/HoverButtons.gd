extends Node

@export_group("Ustawienia Przyciskow")
# Lista przycisków (Shop, Party, Settings)
@export var buttons: Array[Control] = []
# Lista tekstów - wpisz je w edytorze w tej samej kolejności co przyciski!
@export var tooltip_texts: Array[String] = []

@export_group("Ustawienia Chmurki")
# Przeciągnij tutaj swój główny PanelContainer (Chmurkę)
@export var tooltip_panel: PanelContainer 
# Ścieżka do węzła Label wewnątrz Twojej chmurki
@export var label_path: String = "MarginesyTekstu/Tekst"

var active_tweens: Dictionary = {}
var chmurka_label: Label

func _ready() -> void:
	# Na starcie ukrywamy chmurkę i szukamy w niej tekstu
	if tooltip_panel:
		tooltip_panel.hide()
		chmurka_label = tooltip_panel.get_node_or_null(label_path) as Label

	# Przechodzimy przez wszystkie przypisane przyciski
	for i in range(buttons.size()):
		var btn = buttons[i]
		if not btn: 
			continue
		
		# Pobieramy tekst dla danego przycisku. 
		# Jeśli zapomnisz go wpisać w liście tekstów, damy bezpieczny tekst domyślny.
		var text_for_this_button = tooltip_texts[i] if i < tooltip_texts.size() else "Brak opisu"
		
		# Łączymy sygnały najechania myszką, przekazując przycisk oraz jego tekst
		btn.mouse_entered.connect(_on_button_hover.bind(btn, true, text_for_this_button))
		btn.mouse_exited.connect(_on_button_hover.bind(btn, false, ""))
		
		# Początkowa przezroczystość ikony (z poprzedniego kroku)
		var img = btn.get_node_or_null("Margin/IMG")
		if img:
			img.modulate = Color("ffffffa0")

func _on_button_hover(btn: Control, is_hover: bool, text: String) -> void:
	# 1. PŁYNNA ZMIANA KOLORU IKONY (To co wcześniej)
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
	
	# 2. OBSŁUGA CHMURKI (TOOLTIP)
	if not tooltip_panel or not chmurka_label:
		return
		
	if is_hover:
		# Podmieniamy tekst na ten przypisany z @export
		chmurka_label.text = text
		tooltip_panel.show()
		
		# Kilka milisekund czekania (1 klatka), aby Godot zdążył 
		# automatycznie przeskalować PanelContainer do nowego tekstu.
		# Bez tego chmurka pozycjonowałaby się krzywo!
		await get_tree().process_frame
		
		# Obliczamy nową pozycję chmurki (po lewej stronie przycisku)
		var target_x = btn.global_position.x - tooltip_panel.size.x - 10 # 10px luki
		var target_y = btn.global_position.y + (btn.size.y / 2) - (tooltip_panel.size.y / 2) # Wyśrodkowanie w pionie
		
		tooltip_panel.global_position = Vector2(target_x, target_y)
	else:
		tooltip_panel.hide()
