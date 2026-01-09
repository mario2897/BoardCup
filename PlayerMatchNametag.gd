extends Button
class_name PlayerMatchNametag

@onready var label_name = $Divisor/PlayerName
@onready var label_role = $Divisor/PositionBG/Position
@onready var label_score = $Divisor/RatingBG/Rating
@onready var bg_position = $Divisor/PositionBG
@onready var bg_rating = $Divisor/RatingBG

var _base_style: StyleBoxFlat
var _active_highlight: bool = false

func _ready():
	focus_mode = Control.FOCUS_NONE 

func setup(player_data: Dictionary, team_colors: Dictionary):
	# 1. Dati
	label_name.text = " " + str(player_data.get("ShortName", "Player"))
	label_role.text = str(player_data.get("Position", "?"))
	var vote = player_data.get("Vote", "---")
	label_score.text = str(vote)

	# 2. Colori
	var col_pri = team_colors.get("primary", Color.GRAY)
	var col_sec = team_colors.get("secondary", Color.WHITE)
	
	# --- SFONDO (PRIMARIO) ---
	var style = StyleBoxFlat.new()
	style.bg_color = col_pri
	style.bg_color.a = 0.9 # Leggera trasparenza
	# Margini e bordi per separare le targhette
	style.border_width_bottom = 1
	style.border_color = col_pri.darkened(0.2)
	
	add_theme_stylebox_override("normal", style)
	_base_style = style
	
	# Hover & Pressed
	var style_hover = style.duplicate()
	style_hover.bg_color = col_pri.lightened(0.15)
	add_theme_stylebox_override("hover", style_hover)
	
	var style_pressed = style.duplicate()
	style_pressed.bg_color = col_pri.darkened(0.2)
	add_theme_stylebox_override("pressed", style_pressed)

	# --- TESTO (SECONDARIO) ---
	label_name.add_theme_color_override("font_color", col_sec)
	label_role.add_theme_color_override("font_color", col_sec)
	label_score.add_theme_color_override("font_color", col_sec)
	
	# --- BOX RUOLO/VOTO (SCURITI) ---
	bg_position.color = col_pri.darkened(0.3)
	bg_rating.color = col_pri.darkened(0.3)

func update_score(val: String):
	label_score.text = val

func set_highlight(active: bool):
	_active_highlight = active
	if _base_style:
		if active:
			# Bordo Giallo/Oro acceso per il turno
			_base_style.border_width_top = 2
			_base_style.border_width_bottom = 2
			_base_style.border_width_left = 2
			_base_style.border_width_right = 2
			_base_style.border_color = Color(1, 0.9, 0.2) 
		else:
			# Reset bordo normale
			_base_style.border_width_top = 0
			_base_style.border_width_bottom = 1
			_base_style.border_width_left = 0
			_base_style.border_width_right = 0
			_base_style.border_color = _base_style.bg_color.darkened(0.2)
