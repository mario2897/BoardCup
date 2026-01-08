class_name KitSelector
extends VBoxContainer

signal kit_combination_selected(home_kit_path: String, away_kit_path: String)
signal start_match_pressed

# Riferimenti UI
@onready var home_team_name_label: Label = $Teams/HomeColor/HomeTeam/Name
@onready var home_team_logo: TextureRect = $Teams/HomeColor/HomeTeam/Logo
@onready var away_team_name_label: Label = $Teams/AwayColor/AwayTeam/Name
@onready var away_team_logo: TextureRect = $Teams/AwayColor/AwayTeam/Logo

@onready var home_kit_preview: TextureRect = $KitPreviews/HomeKit
@onready var away_kit_preview: TextureRect = $KitPreviews/AwayKit

@onready var button_layout: HBoxContainer = $ButtonsLayout

# Dati Locali
var _home_team_data: Dictionary
var _away_team_data: Dictionary
var _current_home_kit_path: String
var _current_away_kit_path: String

func _ready():
	var buttons = button_layout.get_children()
	
	buttons[0].pressed.connect(_on_kit_button_pressed)
	buttons[1].pressed.connect(_on_kit_button_pressed)
	buttons[2].pressed.connect(_on_kit_button_pressed)
	buttons[3].pressed.connect(_on_kit_button_pressed)
	
	buttons[0].focus_entered.connect(_update_kit_visuals.bind(1, 2)) 
	buttons[1].focus_entered.connect(_update_kit_visuals.bind(2, 2)) 
	buttons[2].focus_entered.connect(_update_kit_visuals.bind(1, 1)) 
	buttons[3].focus_entered.connect(_update_kit_visuals.bind(2, 1)) 
	
	self.visible = false

# --- Funzioni Pubbliche ---

func activate(home_data: Dictionary, away_data: Dictionary):
	_home_team_data = home_data
	_away_team_data = away_data
	
	self.visible = true
	
	home_team_name_label.text = _home_team_data.get("NameShort", "CASA")
	away_team_name_label.text = _away_team_data.get("NameShort", "TRASFERTA")
	
	var home_logo_path = _home_team_data.get("LogoPath", "")
	if FileAccess.file_exists(home_logo_path):
		home_team_logo.texture = load(home_logo_path)
	
	var away_logo_path = _away_team_data.get("LogoPath", "")
	if FileAccess.file_exists(away_logo_path):
		away_team_logo.texture = load(away_logo_path)
	
	# Forza un aggiornamento iniziale (es. 1ª vs 2ª) e dai il focus
	_update_kit_visuals(1, 2)
	button_layout.get_child(0).grab_focus()

func deactivate():
	self.visible = false
	_home_team_data = {}
	_away_team_data = {}
	home_team_logo.texture = null
	away_team_logo.texture = null
	home_kit_preview.texture = null
	away_kit_preview.texture = null

# --- Gestori Interni ---

func _update_kit_visuals(home_kit_num: int, away_kit_num: int):
	if _home_team_data.is_empty() or _away_team_data.is_empty(): return

	var home_kit_col_name = "HomeKitPath" if home_kit_num == 1 else "AwayKitPath"
	var away_kit_col_name = "HomeKitPath" if away_kit_num == 1 else "AwayKitPath"
	
	_current_home_kit_path = _home_team_data.get(home_kit_col_name, "")
	_current_away_kit_path = _away_team_data.get(away_kit_col_name, "")
	
	if FileAccess.file_exists(_current_home_kit_path):
		home_kit_preview.texture = load(_current_home_kit_path)
	else:
		home_kit_preview.texture = null

	if FileAccess.file_exists(_current_away_kit_path):
		away_kit_preview.texture = load(_current_away_kit_path)
	else:
		away_kit_preview.texture = null
	
	emit_signal("kit_combination_selected", _current_home_kit_path, _current_away_kit_path)


# --- MODIFICA: AVVIO E INIZIALIZZAZIONE DB ---

func _on_kit_button_pressed():
	print("Selezione completata. Inizializzazione dati partita...")
	
	# 1. Aggiorna GlobalVariables con le scelte definitive
	GlobalVariables.HomeKitPath = _current_home_kit_path
	GlobalVariables.AwayKitPath = _current_away_kit_path
	GlobalVariables.HomeTeamID = _home_team_data.get("TeamID")
	GlobalVariables.AwayTeamID = _away_team_data.get("TeamID")
	
	# 2. SCRITTURA NEL DB (Crea la "Sandbox")
	# Svuota le tabelle temporanee e copia i dati attuali
	
	var is_fantasy = (GlobalVariables.ModalitàPartita == "Fantasy")
	
	# A. Init Tabella CurrentMatch (Punteggio, Kit, Stato)
	DataManager.init_match_data(
		GlobalVariables.HomeTeamID, 
		GlobalVariables.AwayTeamID, 
		GlobalVariables.HomeKitPath, 
		GlobalVariables.AwayKitPath
	)
	
	# B. Init Tabella MatchRosters (Copia i giocatori)
	# Questo permette alla scena successiva di leggere/modificare la formazione
	# senza toccare i dati originali.
	DataManager.init_match_roster(
		GlobalVariables.HomeTeamID, 
		GlobalVariables.AwayTeamID, 
		is_fantasy
	)
	
	# 3. CAMBIO SCENA
	emit_signal("start_match_pressed")
	
	if is_fantasy:
		# Scena Fantasy (con Dadi e Stelle)
		get_tree().change_scene_to_file("res://Scenes/StartersSelection.tscn")
	else:
		# Scena RPG (Club reali)
		# Nota: Nel tuo codice originale era LineUpSelection.tscn, controlla il nome file!
		get_tree().change_scene_to_file("res://Scenes/LineUpSelection.tscn")
