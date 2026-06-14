extends Panel

# Tutaj w Inspektorze klikasz "Add Element" i dodajesz swoje przyciski (Shop, Party, Settings)
@export var buttons: Array[Control] = []

# Słownik do pilnowania aktywnych animacji, żeby płynne przejścia się nie gryzły
var active_tweens: Dictionary = {}

func _ready() -> void:
	for btn in buttons:
		# Łączymy sygnały najechania i zjechania myszką z naszą funkcją
		btn.mouse_entered.connect(_on_button_hover.bind(btn, true))
		btn.mouse_exited.connect(_on_button_hover.bind(btn, false))
		
		# Ustawiamy początkowy stan na ffffffa0 (lekko przezroczysty)
		var img = btn.get_node_or_null("Margin/IMG")
		if img:
			img.modulate = Color("ffffffa0")

func _on_button_hover(btn: Control, is_hover: bool) -> void:
	# Szukamy obrazka wewnątrz przycisku (używamy poprawnej ścieżki z drzewa)
	var img = btn.get_node_or_null("Margin/IMG")
	if not img:
		return
		
	# Bezpiecznik: jeśli obrazek już się animuje (np. szybko machasz myszką),
	# zatrzymujemy poprzednią animację, żeby przejście było idealnie płynne
	if active_tweens.has(btn) and active_tweens[btn].is_running():
		active_tweens[btn].kill()
		
	# Wybieramy docelowy kolor na podstawie tego, czy myszka weszła, czy zeszła
	var target_color = Color("ffffff") if is_hover else Color("ffffffa0")
	
	# Tworzymy nowego Tweena dla tego konkretnego przycisku
	var tween = create_tween()
	active_tweens[btn] = tween
	
	# Animujemy właściwość 'modulate' do docelowego koloru w czasie 0.15 sekundy
	# TRANS_CUBIC i EASE_OUT dają ładne, miękkie i nowoczesne wyhamowanie animacji
	tween.tween_property(img, "modulate", target_color, 0.15)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
