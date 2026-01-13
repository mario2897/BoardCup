extends Control

# ==============================================================================
# 1. RIFERIMENTI E COSTANTI
# ==============================================================================
const FIELD_BTN_SCENE = preload("res://Scenes/Prefabs/PlayerButtonField.tscn")
const LIST_BTN_SCENE = preload("res://Scenes/Prefabs/PlayerButtonList.tscn")

# Header Squadra
@onready var team_name_label: Label = $Team/Name
@onready var team_logo_rect: TextureRect = $Team/Logo

# Pannello Sinistro: Calendario
@onready var league_games_list: VBoxContainer = $GridContainer/LeagueGames
@onready var match_row_template: HBoxContainer = $GridContainer/LeagueGames/MatchContainer

# Pannello Destro: Campo da Gioco
@onready var strikers_container: HBoxContainer = $GridContainer/SelectionContainer/Pitch/Roles/Strikers
@onready var midfielders_container: HBoxContainer = $GridContainer/SelectionContainer/Pitch/Roles/Midfielders
@onready var defenders_container: HBoxContainer = $GridContainer/SelectionContainer/Pitch/Roles/Defenders
@onready var goalkeepers_container: HBoxContainer = $GridContainer/SelectionContainer/Pitch/Roles/GoalKeepers

# Pannello Destro: Panchina
@onready var bench_list_container: VBoxContainer = $GridContainer/SelectionContainer/PlayerList/BenchList

# Variabili di Stato
var _user_fantasy_team_id: int = 0
var _team_kit_texture: Texture2D = null
var _league_fixtures: Array = []
var _selected_btn: Control = null # Il bottone attualmente selezionato per lo scambio

# ==============================================================================
# 2. INIZIALIZZAZIONE
# ==============================================================================
func _ready():
	# 1. Determina l'ID della squadra dell'utente
	if GlobalVariables.MatchType == "CPU_P1":
		_user_fantasy_team_id = GlobalVariables.AwayTeamID
	else:
		_user_fantasy_team_id = GlobalVariables.HomeTeamID

	# 2. Nascondi i template usati per clonazione
	if match_row_template: match_row_template.visible = false
	
	# 3. Avvia il popolamento della UI
	refresh_ui()
	
	# 4. Focus iniziale (per gamepad/tastiera)
	call_deferred("_force_initial_focus")

# Funzione centrale per ricaricare tutto
func refresh_ui(id_to_focus: int = -1):
	_selected_btn = null
	
	populate_team_info()       # Logo e Nome
	populate_league_fixtures() # Calendario a sinistra
	populate_user_roster()     # Campo e Panchina a destra
	
	if id_to_focus != -1:
		call_deferred("_restore_focus_to_id", id_to_focus)

# ==============================================================================
# 3. INFO SQUADRA
# ==============================================================================
func populate_team_info():
	var team_data = DataManager.get_fantasy_team_data(_user_fantasy_team_id)
	if not team_data: return

	team_name_label.text = team_data.get("NameShort", "Team")
	
	# Logo
	var logo_path = team_data.get("LogoPath", "")
	if FileAccess.file_exists(logo_path):
		team_logo_rect.texture = load(logo_path)
	
	# Kit (Maglia)
	var kit_path = ""
	if _user_fantasy_team_id == GlobalVariables.HomeTeamID:
		kit_path = GlobalVariables.HomeKitPath
	elif _user_fantasy_team_id == GlobalVariables.AwayTeamID:
		kit_path = GlobalVariables.AwayKitPath
	
	# Fallback sul kit di default del team se non settato nella partita
	if kit_path == "": kit_path = team_data.get("KitPath", "")
	
	if FileAccess.file_exists(kit_path):
		_team_kit_texture = load(kit_path)
	else:
		_team_kit_texture = null

# ==============================================================================
# 4. CALENDARIO (Generazione e Rendering)
# ==============================================================================
func populate_league_fixtures():
	# Pulisci lista visiva precedente
	for child in league_games_list.get_children():
		if child != match_row_template:
			child.queue_free()
	
	# --- LOGICA GENERAZIONE ---
	if _league_fixtures.is_empty():
		# Prova a leggere dal DataManager (cache)
		_league_fixtures = DataManager.get_real_schedule()
		
		# Se ancora vuoto (Primo Avvio), genera nuova giornata
		if _league_fixtures.is_empty():
			print("🎲 Generazione Calendario Reale...")
			_league_fixtures = DataManager.get_league_matchday("ITA1")
			DataManager.set_real_schedule(_league_fixtures) # Salva in cache globale

	# --- RENDERING ---
	for match_data in _league_fixtures:
		var row = match_row_template.duplicate()
		
		var h_name = str(match_data.get("Home_Abbr", "")).left(3)
		if h_name == "": h_name = str(match_data.get("Home_Name", "HOM")).left(3).to_upper()
		
		var a_name = str(match_data.get("Away_Abbr", "")).left(3)
		if a_name == "": a_name = str(match_data.get("Away_Name", "AWY")).left(3).to_upper()
			
		row.get_node("NameHome").text = h_name
		row.get_node("NameAway").text = a_name
		
		var h_logo = match_data.get("Home_Logo", "")
		var a_logo = match_data.get("Away_Logo", "")
		if FileAccess.file_exists(h_logo): row.get_node("HomeTeamLogo/LogoHome").texture = load(h_logo)
		if FileAccess.file_exists(a_logo): row.get_node("AwayTeamLogo/LogoAway").texture = load(a_logo)
		
		row.visible = true
		league_games_list.add_child(row)

# ==============================================================================
# 5. ROSTER (Titolari e Panchina)
# ==============================================================================
func populate_user_roster():
	# 1. PULIZIA TOTALE (Previene duplicati)
	_clear_all_containers()

	# 2. RECUPERO DATI
	var starters = DataManager.get_match_roster_starters(_user_fantasy_team_id)
	var bench = DataManager.get_match_roster_bench(_user_fantasy_team_id)
	
	print("📊 Roster: %d Titolari, %d Panchinari" % [starters.size(), bench.size()])
	
	# 3. TITOLARI (CAMPO)
	for p_data in starters:
		var pos = p_data.get("Position", "A")
		var target_container = strikers_container
		
		match pos:
			"P", "GK": target_container = goalkeepers_container
			"D", "DEF": target_container = defenders_container
			"C", "MID": target_container = midfielders_container
			"A", "ATT": target_container = strikers_container
		
		_create_and_add_btn(p_data, true, target_container)
		
	# 4. PANCHINA (LISTA)
	for p_data in bench:
		_create_and_add_btn(p_data, false, bench_list_container)
	
	setup_custom_navigation()

func _create_and_add_btn(data: Dictionary, is_starter: bool, parent: Control):
	if parent == null: return
	
	var btn = null
	if is_starter:
		btn = FIELD_BTN_SCENE.instantiate()
	else:
		btn = LIST_BTN_SCENE.instantiate()
	
	parent.add_child(btn)
	
	# Configurazione
	if is_starter:
		# Field Button: vuole dati e texture kit
		if btn.has_method("setup"):
			btn.setup(data, _team_kit_texture)
		btn.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	else:
		# List Button: vuole solo dati
		if btn.has_method("setup"):
			btn.setup(data)
		btn.size_flags_horizontal = Control.SIZE_FILL
	
	# Collegamento Click
	if btn.has_signal("pressed"):
		if not btn.pressed.is_connected(_on_player_clicked):
			btn.pressed.connect(_on_player_clicked.bind(btn))
	
	# Meta dati per identificazione
	btn.set_meta("player_id", data.get("PlayerID"))

func _clear_all_containers():
	var all_containers = [strikers_container, midfielders_container, defenders_container, goalkeepers_container, bench_list_container]
	for c in all_containers:
		if c:
			for child in c.get_children():
				c.remove_child(child) # Rimuove dalla scena
				child.queue_free()    # Libera memoria

# ==============================================================================
# 6. LOGICA DI SWAP (SCAMBIO)
# ==============================================================================
func _on_player_clicked(btn_clicked):
	# Caso 1: Nessuna selezione precedente -> Seleziona
	if _selected_btn == null:
		_select_button(btn_clicked)
		return
	
	# Caso 2: Cliccato lo stesso bottone -> Deseleziona
	if _selected_btn == btn_clicked:
		_deselect_button()
		return
		
	# Caso 3: Cliccato un bottone diverso -> SCAMBIO
	if _selected_btn != btn_clicked:
		var id_source = _selected_btn.get_meta("player_id")
		var id_target = btn_clicked.get_meta("player_id")
		
		print("🔄 Swap Player %s <-> %s" % [id_source, id_target])
		
		# Esegui lo scambio nel DB
		DataManager.swap_match_roster_status(id_source, id_target)
		
		# Aggiorna la UI
		_deselect_button() # Resetta stato grafico
		refresh_ui(id_target) # Ricarica tutto e focalizza il nuovo

func _select_button(btn):
	_selected_btn = btn
	btn.modulate = Color.YELLOW # Feedback visivo semplice
	# Se il tuo bottone ha uno stato "selected", usalo qui

func _deselect_button():
	if _selected_btn != null and is_instance_valid(_selected_btn):
		_selected_btn.modulate = Color.WHITE
	_selected_btn = null

# ==============================================================================
# 7. NAVIGAZIONE (Controller/Tastiera)
# ==============================================================================
func _force_initial_focus():
	if strikers_container.get_child_count() > 0:
		strikers_container.get_child(0).grab_focus()

func _restore_focus_to_id(target_id: int):
	var all_containers = [strikers_container, midfielders_container, defenders_container, goalkeepers_container, bench_list_container]
	for c in all_containers:
		for btn in c.get_children():
			if btn.get_meta("player_id") == target_id:
				btn.grab_focus()
				return

func setup_custom_navigation():
	# Implementa qui logiche avanzate di navigazione (neighbor_top/bottom) se necessario
	pass

# ==============================================================================
# 8. AVVIO PARTITA
# ==============================================================================
func _on_PlayMatch_pressed():
	print("🚀 Avvio Partita...")
	
	# 1. Salva il calendario generato nel DataManager (Critico per TurnManager)
	if not _league_fixtures.is_empty():
		DataManager.set_real_schedule(_league_fixtures)
	
	# 2. Calcola e scrivi i modificatori di difficoltà nel DB
	DataManager.applica_modificatori_giornata(_league_fixtures)
	
	# 3. Cambia scena
	get_tree().change_scene_to_file("res://Scenes/MatchFantasy.tscn")
