extends PanelContainer

@onready var arrow_anchor: Control = $ArrowAnchor/Arrow

func _process(_delta: float) -> void:
	if arrow_anchor:
		# 1. Bierzemy pełną szerokość chmurki (self.size.x), co daje nam idealnie prawą krawędź.
		# 2. Odejmujemy 1.0 piksel, żeby strzałka minimalnie "wjechała" na panel i zlikwidowała szparkę.
		#    (Jeśli po testach nadal zobaczysz mikro-szparkę, zmień - 1.0 na - 2.0).
		arrow_anchor.position.x = self.size.x + 4.3
		
		# 3. Zaokrąglamy też pozycję Y, żeby pionowa krawędź nie dostała ułamków i nie była rozmyta.
		arrow_anchor.position.y = round(arrow_anchor.position.y)
