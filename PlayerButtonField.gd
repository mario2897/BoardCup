extends Button
class_name PlayerButtonField

# --- RIFERIMENTI AI NODI ---
@onready var jersey_rect: TextureRect = $JerseyName/Jersey
@onready var name_lbl: Label = $JerseyName/NameBG/PlayerName

# --- DATI PUBBLICI ---
var player_id: int
var position_role: String
var is_starter: bool = true 

# --- COLORI TESTO ---
const TEXT_COLOR_NORMAL = Color.BLACK 
const TEXT_COLOR_FOCUS = Color.BLACK 

func _ready():
	focus_mode = Control.FOCUS_ALL
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)

func setup(data: Dictionary, kit_texture: Texture2D):
	player_id = data.get("PlayerID")
	
	# --- MODIFICA QUI: USO DI SHORTNAME ---
	# Cerchiamo "ShortName". Se è null o vuoto (nel caso qualcosa sia andato storto nel DB),
	# usiamo "Name" come sicurezza (fallback).
	var display_name = data.get("ShortName")
	
	if display_name == null or str(display_name) == "":
		display_name = data.get("Name", "Sconosciuto")
	
	# Impostiamo il ruolo
	if data.has("Role"): position_role = data.get("Role")
	else: position_role = data.get("Position", "?")
	
	# 1. IMPOSTA NOME (Diretto dal DB, senza calcoli)
	name_lbl.text = str(display_name)
	name_lbl.add_theme_color_override("font_color", TEXT_COLOR_NORMAL)

	# 2. IMPOSTA MAGLIA
	if kit_texture:
		jersey_rect.texture = kit_texture

# --- GESTIONE VISIVA FOCUS ---
func _on_focus_entered():
	name_lbl.add_theme_color_override("font_color", TEXT_COLOR_FOCUS)

func _on_focus_exited():
	name_lbl.add_theme_color_override("font_color", TEXT_COLOR_NORMAL)
