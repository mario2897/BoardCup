extends VBoxContainer

# Riferimenti ai nodi interni
@onready var dot_icon: Panel = $DotIcon
@onready var name_label: Label = $PlayerName

# Variabile per memorizzare il bordo originale (per ripristinarlo dopo l'highlight)
var _original_secondary: Color = Color.WHITE
var _style_box: StyleBoxFlat

func _ready():
	# Clona lo stile per renderlo unico per questa pedina
	if dot_icon:
		var current_style = dot_icon.get_theme_stylebox("panel")
		if current_style:
			_style_box = current_style.duplicate()
			dot_icon.add_theme_stylebox_override("panel", _style_box)

func setup(player_data: Dictionary, primary_col: Color, secondary_col: Color):
	# 1. Imposta Testi
	name_label.text = player_data.get("ShortName", "Player")
	# Nascondi il nome di default se vuoi (o mostralo solo in hover)
	# name_label.visible = false 
	
	# 2. Salva colori
	_original_secondary = secondary_col
	
	# 3. Applica Colori allo StyleBox
	if _style_box:
		_style_box.bg_color = primary_col
		_style_box.border_color = secondary_col
		# Reset bordi standard
		_style_box.border_width_left = 5
		_style_box.border_width_top = 5
		_style_box.border_width_right = 5
		_style_box.border_width_bottom = 5

func highlight(active: bool):
	if not _style_box: return
	
	if active:
		# MODALITÀ ATTIVA: Bordo Giallo Fluo + Ingrandimento
		_style_box.border_color = Color(1, 1, 0) # Giallo
		_style_box.border_width_left = 8
		_style_box.border_width_top = 8
		_style_box.border_width_right = 8
		_style_box.border_width_bottom = 8
		
		dot_icon.scale = Vector2(1.2, 1.2)
		name_label.modulate = Color(1, 1, 0) # Colora anche il nome
		z_index = 10 # Porta in primo piano
	else:
		# RIPRISTINO
		_style_box.border_color = _original_secondary
		_style_box.border_width_left = 5
		_style_box.border_width_top = 5
		_style_box.border_width_right = 5
		_style_box.border_width_bottom = 5
		
		dot_icon.scale = Vector2(1.0, 1.0)
		name_label.modulate = Color.WHITE
		z_index = 0
