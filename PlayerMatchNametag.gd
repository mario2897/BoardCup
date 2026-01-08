extends Button
class_name PlayerMatchNametag

# Riferimenti ai Nodi
@onready var label_role = $Divisor/PositionBG/Position
@onready var label_name = $Divisor/PlayerName
@onready var label_score = $Divisor/RatingBG/Rating
@onready var bg_position = $Divisor/PositionBG
@onready var bg_rating = $Divisor/RatingBG

# Dati interni
var player_id: int
var _base_style: StyleBoxFlat # Salviamo lo stile base per manipolarlo

func _ready():
	# Opzionale: Rimuove il focus da tastiera (tab) se non vuoi che si evidenzi navigando
	focus_mode = Control.FOCUS_NONE 

func setup(player_data: Dictionary, team_colors: Dictionary):
	player_id = int(player_data.get("PlayerID", 0))
	
	# 1. Testi
	label_name.text = " " + str(player_data.get("Name", "Sconosciuto"))
	label_role.text = str(player_data.get("Position", "?"))
	update_score("---")

	# 2. Colori
	var primary = team_colors.get("primary", Color.GRAY)
	var secondary = team_colors.get("secondary", Color.WHITE)
	
	# --- CONFIGURAZIONE STILI BOTTONE ---
	
	# Stile NORMALE
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = primary
	style_normal.bg_color.a = 0.2 # Sfondo leggero
	add_theme_stylebox_override("normal", style_normal)
	
	# Stile HOVER (Quando passi il mouse: un po' più opaco)
	var style_hover = style_normal.duplicate()
	style_hover.bg_color.a = 0.4 
	add_theme_stylebox_override("hover", style_hover)
	
	# Stile PRESSED (Quando clicchi: colore pieno ma scuro)
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = primary.darkened(0.2)
	style_pressed.bg_color.a = 0.6
	add_theme_stylebox_override("pressed", style_pressed)
	
	# Salviamo lo stile normale per poter cambiare il bordo (evidenziatore) dopo
	_base_style = style_normal

	# --- CONFIGURAZIONE SOTTO-ELEMENTI ---
	# Box interni (Ruolo e Voto) colore pieno
	bg_position.color = primary
	bg_rating.color = primary
	
	# Testi
	label_role.add_theme_color_override("font_color", secondary)
	label_score.add_theme_color_override("font_color", secondary)
	label_name.add_theme_color_override("font_color", Color.BLACK)

# Aggiorna Voto
func update_score(val: String):
	label_score.text = val

# Evidenzia il giocatore (Turno Attivo)
func set_highlight(active: bool):
	if _base_style:
		if active:
			# Aggiunge bordo Oro
			_base_style.border_width_bottom = 2
			_base_style.border_width_top = 2
			_base_style.border_width_left = 2
			_base_style.border_width_right = 2
			_base_style.border_color = Color(1, 0.8, 0, 1)
		else:
			# Rimuove bordo
			_base_style.border_width_bottom = 0
			_base_style.border_width_top = 0
			_base_style.border_width_left = 0
			_base_style.border_width_right = 0
