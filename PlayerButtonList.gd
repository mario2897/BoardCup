extends Button
class_name PlayerButtonList

# --- RIFERIMENTI ---
@onready var role_badge: ColorRect = $Divisor/ColorRect
@onready var role_lbl: Label = $Divisor/ColorRect/Position
@onready var name_lbl: Label = $Divisor/PlayerName

# --- DATI ---
var player_id: int
var position_role: String
var is_starter: bool = false 

# --- COLORI RUOLI ---
const COLOR_GK = Color("#e6b800")
const COLOR_DEF = Color("#0073e6")
const COLOR_MID = Color("#00b33c")
const COLOR_ATT = Color("#e62e00")
const COLOR_DEFAULT = Color("#000000")

# --- COLORI TESTO (Definisci qui i colori esatti) ---
const TEXT_COLOR_NORMAL = Color.BLACK
const TEXT_COLOR_FOCUS = Color.WHITE 

func _ready():
	focus_mode = Control.FOCUS_ALL
	
	# Connetti i segnali
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)

func setup(data: Dictionary):
	player_id = data.get("PlayerID")
	var full_name = data.get("Name", "Sconosciuto")
	
	if data.has("Role"): position_role = data.get("Role")
	else: position_role = data.get("Position", "?")
	
	name_lbl.text = "  " + full_name
	
	# Imposta il colore iniziale forzandolo
	name_lbl.add_theme_color_override("font_color", TEXT_COLOR_NORMAL)
	role_lbl.text = position_role
	
	match position_role:
		"P": role_badge.color = COLOR_GK
		"D": role_badge.color = COLOR_DEF
		"C": role_badge.color = COLOR_MID
		"A": role_badge.color = COLOR_ATT
		_: role_badge.color = COLOR_DEFAULT

# --- GESTIONE COLORE TESTO (Usa override, non modulate) ---

func _on_focus_entered():
	# Forza il colore del font
	name_lbl.add_theme_color_override("font_color", TEXT_COLOR_FOCUS)

func _on_focus_exited():
	# Ripristina il colore normale
	name_lbl.add_theme_color_override("font_color", TEXT_COLOR_NORMAL)
