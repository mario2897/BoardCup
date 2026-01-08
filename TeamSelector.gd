extends Control

# Riferimenti Schermata 1
@onready var game_selection_screen: VBoxContainer = $Background/GameSelection
@onready var first_button = $Background/GameSelection/P1vCPU

# Riferimenti Schermata 2
@onready var selection_layout: VBoxContainer = $Background/SelectionLayout
@onready var teams_scene_screen: GridContainer = $Background/SelectionLayout/TeamsScene
@onready var home_team_panel: TeamSelectionPanel = $Background/SelectionLayout/TeamsScene/HomeTeamPanel
@onready var away_team_panel: TeamSelectionPanel = $Background/SelectionLayout/TeamsScene/AwayTeamPanel

# Riferimento alla Scena KitSelector
@onready var kit_selector: KitSelector = $Background/SelectionLayout/KitSelector

# Stato Interno
var _selected_home_team = null
var _selected_away_team = null
var _home_kit_path: String
var _away_kit_path: String
var _is_fantasy_mode: bool = false


func _ready():
	first_button.grab_focus()
	game_selection_screen.visible = true
	selection_layout.visible = false 
	
	# Connetti i segnali dei pannelli
	home_team_panel.team_selected.connect(_on_HomeTeam_selected)
	away_team_panel.team_selected.connect(_on_AwayTeam_selected)
	
	# Connetti il segnale per tornare indietro
	home_team_panel.back_to_menu_requested.connect(_on_back_to_main_menu)
	away_team_panel.back_to_menu_requested.connect(_on_back_to_main_menu)
	
	kit_selector.kit_combination_selected.connect(_on_kit_combination_selected)
	kit_selector.start_match_pressed.connect(_on_start_match_pressed)
	
	# Disattiva tutto all'inizio
	home_team_panel.deactivate()
	away_team_panel.deactivate()
	kit_selector.deactivate()


# --- 1. Gestione Schermate e Modalità ---

func _on_button_pressed(mode_name: String):
	GlobalVariables.MatchType = mode_name
	print("Mode: ", GlobalVariables.MatchType)
	
	game_selection_screen.visible = false
	selection_layout.visible = true 
	teams_scene_screen.visible = true
	kit_selector.deactivate() 
	
	_selected_home_team = null
	_selected_away_team = null
	
	# --- FIX LAYOUT E FOCUS ---
	
	# 1. Assicurati che entrambi siano visibili per occupare lo spazio nel GridContainer
	home_team_panel.visible = true
	away_team_panel.visible = true
	
	# 2. Disattiva entrambi (diventano trasparenti e non cliccabili)
	home_team_panel.deactivate()
	away_team_panel.deactivate()
	
	# 3. Configura la modalità Fantasy su entrambi SUBITO
	if GlobalVariables.ModalitàPartita == "Fantasy":
		_is_fantasy_mode = true
	else:
		_is_fantasy_mode = false
	
	home_team_panel.set_fantasy_mode(_is_fantasy_mode)
	away_team_panel.set_fantasy_mode(_is_fantasy_mode)
	
	# 4. Attiva solo quello necessario
	match mode_name:
		"P1_CPU", "P1_P2", "CPU_CPU", "Fantasy":
			_activate_panel(true) # Attiva Home (Sinistra)
		"CPU_P1", "P2_P1":
			_activate_panel(false) # Attiva Away (Destra)
		_:
			_activate_panel(true)

# --- Funzione Tornare al Menu ---
func _on_back_to_main_menu():
	game_selection_screen.visible = true
	selection_layout.visible = false
	
	# Resetta stato
	home_team_panel.deactivate()
	away_team_panel.deactivate()
	kit_selector.deactivate()
	
	first_button.grab_focus()


# --- 2. Gestore di Stato ---

func _activate_panel(activate_home: bool):
	if activate_home:
		# Riattiva Home (diventa opaco e cliccabile)
		home_team_panel.activate()
		
		if _selected_away_team == null: 
			# Se Away non è scelto, resta disattivato (trasparente e NO focus)
			away_team_panel.deactivate()
		else:
			# Se Away era già scelto, mostra lo stato completato
			away_team_panel.show_completed_state(_selected_away_team)
	else:
		# Riattiva Away
		away_team_panel.activate()
		
		if _selected_home_team == null: 
			# Home resta disattivato (trasparente e NO focus) ma VISIBILE per il layout
			home_team_panel.deactivate()
		else:
			home_team_panel.show_completed_state(_selected_home_team)

# --- 3. Gestori dei Segnali Squadra ---

func _on_HomeTeam_selected(team_data: Dictionary):
	_selected_home_team = team_data
	
	if _selected_away_team == null:
		_activate_panel(false) # Tocca ad Away
	else:
		_check_if_ready_to_start() # Finito

func _on_AwayTeam_selected(team_data: Dictionary):
	_selected_away_team = team_data

	if _selected_home_team == null:
		_activate_panel(true) # Tocca a Home
	else:
		_check_if_ready_to_start() # Finito

# --- 4. Logica di Completamento ---

func _check_if_ready_to_start():
	if _selected_home_team != null and _selected_away_team != null:
		# Nascondi i pannelli solo quando passi ai Kit
		home_team_panel.visible = false
		away_team_panel.visible = false
		teams_scene_screen.visible = false
		
		kit_selector.activate(_selected_home_team, _selected_away_team)

# --- 5. Gestori Segnali KitSelector ---

func _on_kit_combination_selected(home_path: String, away_path: String):
	_home_kit_path = home_path
	_away_kit_path = away_path

func _on_start_match_pressed():
	GlobalVariables.HomeTeamID = _selected_home_team.get("TeamID")
	GlobalVariables.AwayTeamID = _selected_away_team.get("TeamID")
	GlobalVariables.HomeKitPath = _home_kit_path
	GlobalVariables.AwayKitPath = _away_kit_path

	var home_name = _selected_home_team.get("Name", "Casa")
	var away_name = _selected_away_team.get("Name", "Trasferta")
	print("Partita pronta per iniziare!")
	print("%s vs %s" % [home_name, away_name])
	
func _on_Back_pressed():
	if(GlobalVariables.ModalitàPartita=="Fantasy") :
		get_tree().change_scene_to_file("res://Scenes/MenuFantasy.tscn")
	else :
		get_tree().change_scene_to_file("res://Scenes/MenuGDR.tscn")
