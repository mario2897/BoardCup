extends Control

# --- SCENE PREFAB ---
const PLAYER_BTN_SCENE = preload("res://Scenes/Prefabs/PlayerButtonList.tscn")

# --- RIFERIMENTI UI ---

# Pannello CASA (Sinistra)
@onready var home_team_name: Label = $Columns/HomeTeamLineup/HomeTeam/HomeTeamSelected/TeamName
@onready var home_team_logo: TextureRect = $Columns/HomeTeamLineup/HomeTeam/HomeTeamSelected/TeamLogo
@onready var home_formation_image: TextureRect = $Columns/HomeTeamLineup/HomeTeam/Modulo
@onready var home_starters_list: VBoxContainer = $Columns/HomeTeamLineup/HomeTeam/PlayersHome/Starters
@onready var home_bench_list: VBoxContainer = $Columns/HomeTeamLineup/HomeTeam/PlayersHome/Bench

# Pannello OSPITI (Destra)
@onready var away_team_name: Label = $Columns/AwayTeamLineup/AwayTeam/AwayTeamSelected/TeamName
@onready var away_team_logo: TextureRect = $Columns/AwayTeamLineup/AwayTeam/AwayTeamSelected/TeamLogo
@onready var away_formation_image: TextureRect = $Columns/AwayTeamLineup/AwayTeam/Modulo
@onready var away_starters_list: VBoxContainer = $Columns/AwayTeamLineup/AwayTeam/PlayersAway/Starters
@onready var away_bench_list: VBoxContainer = $Columns/AwayTeamLineup/AwayTeam/PlayersAway/Bench

# Pannello Centrale
@onready var start_match_button: Button = $Columns/MatchOptions/StartMatchButton

# --- DATI DI STATO ---
var _home_id: int
var _away_id: int

# Logica Selezione
var _selected_btn: Control = null 
var _user_side: String = "home" # "home" o "away"

func _ready():
	# 1. Recupera ID
	_home_id = GlobalVariables.HomeTeamID
	_away_id = GlobalVariables.AwayTeamID
	
	# 2. Determina lato utente
	if GlobalVariables.MatchType == "CPU_P1" or GlobalVariables.MatchType == "P2_P1":
		_user_side = "away"
	else:
		_user_side = "home"
	
	# 3. Carica Info Statiche
	_load_team_info(_home_id, home_team_name, home_team_logo)
	_load_team_info(_away_id, away_team_name, away_team_logo)
	
	# 4. Popola liste
	refresh_ui()
	
	# 5. Connetti Start
	if start_match_button:
		start_match_button.pressed.connect(_on_start_match_pressed)

	# 6. Focus Iniziale
	_force_initial_focus()


# ==============================================================================
#  1. GESTIONE UI E POPOLAMENTO
# ==============================================================================

func _load_team_info(team_id: int, lbl_name: Label, tex_logo: TextureRect):
	var data = DataManager.get_team_data(team_id)
	if data:
		lbl_name.text = data.get("NameShort", "Team")
		var path = data.get("LogoPath", "")
		if FileAccess.file_exists(path):
			tex_logo.texture = load(path)

func refresh_ui(id_to_focus: int = -1):
	# Resetta riferimento selezione (il nodo verrà distrutto)
	_selected_btn = null 

	# Ricarica liste leggendo da MatchRostersRPG
	_populate_side(_home_id, home_starters_list, home_bench_list, home_formation_image, "home")
	_populate_side(_away_id, away_starters_list, away_bench_list, away_formation_image, "away")
	
	# Applica blocchi navigazione
	_enforce_navigation_lock()
	
	# Ripristina focus tastiera se necessario
	if id_to_focus != -1:
		_restore_focus_to_id(id_to_focus)

func _populate_side(team_id: int, list_starters: VBoxContainer, list_bench: VBoxContainer, img_formation: TextureRect, side: String):
	# Pulisci
	for c in list_starters.get_children(): c.queue_free()
	for c in list_bench.get_children(): c.queue_free()
	
	# Leggi DB Temporaneo
	var starters = DataManager.get_match_roster_starters(team_id)
	var bench = DataManager.get_match_roster_bench(team_id)
	
	# Crea Bottoni
	for p in starters: _create_player_btn(p, list_starters, side)
	for p in bench: _create_player_btn(p, list_bench, side)
		
	# Aggiorna Modulo Grafico
	_update_formation_texture(starters, img_formation)

func _create_player_btn(data: Dictionary, parent: VBoxContainer, side: String):
	var btn = PLAYER_BTN_SCENE.instantiate()
	
	# 1. Aggiungi PRIMA (evita errori @onready)
	parent.add_child(btn)
	
	# 2. Manipola nome (Solo Cognome)
	var display_data = data.duplicate()
	var full_name = display_data.get("Name", "")
	display_data["Name"] = get_complete_surname(full_name).capitalize()
	
	# 3. Configura
	btn.setup(display_data)
	
	# 4. Metadati e Connessioni
	btn.set_meta("side", side)
	
	# IMPORTANTE: Assicurati che il bottone nel tscn abbia Toggle Mode = ON
	btn.pressed.connect(_on_player_clicked.bind(btn))


# ==============================================================================
#  2. LOGICA CLICK & SWAP (Gestita dal Tema)
# ==============================================================================

func _on_player_clicked(btn_clicked):
	# Sicurezza: Non cliccare avversari
	if btn_clicked.get_meta("side") != _user_side: 
		btn_clicked.button_pressed = false
		return 
	
	# A. NESSUNO SELEZIONATO -> SELEZIONA
	if _selected_btn == null:
		_select_button(btn_clicked)
		return
	
	# B. CLICCO STESSO BOTTONE -> DESELEZIONA
	if _selected_btn == btn_clicked:
		_deselect_button()
		return
		
	# C. CLICCO UN ALTRO -> SWAP
	if _selected_btn != btn_clicked:
		print("🔄 Swap: %s <-> %s" % [_selected_btn.name_lbl.text, btn_clicked.name_lbl.text])
		
		# ID per ripristinare il focus dopo il refresh
		var id_to_keep = btn_clicked.player_id
		
		# Spegni il bottone appena cliccato (lo stato toggle lo aveva acceso)
		btn_clicked.button_pressed = false
		
		# Esegui scambio su DB
		DataManager.swap_match_roster_status(_selected_btn.player_id, btn_clicked.player_id)
		
		_deselect_button()
		refresh_ui(id_to_keep) # Ricarica UI e ridà focus

func _select_button(btn):
	_selected_btn = btn
	# Attiva lo stato "Pressed" per far agire il Tema
	btn.button_pressed = true 

func _deselect_button():
	if _selected_btn != null and is_instance_valid(_selected_btn):
		# Disattiva lo stato "Pressed"
		_selected_btn.button_pressed = false
	_selected_btn = null


# ==============================================================================
#  3. NAVIGAZIONE E BLOCCHI (Side Lock)
# ==============================================================================

func _enforce_navigation_lock():
	await get_tree().process_frame
	
	var disable_list = []
	var enable_list = []
	
	if _user_side == "home":
		disable_list = [away_starters_list, away_bench_list]
		enable_list = [home_starters_list, home_bench_list]
	else:
		disable_list = [home_starters_list, home_bench_list]
		enable_list = [away_starters_list, away_bench_list]
	
	# Disabilita Avversari (Grigi e non focusabili)
	for container in disable_list:
		for btn in container.get_children():
			btn.focus_mode = Control.FOCUS_NONE
			btn.disabled = true
			btn.modulate.a = 0.5 
			
	# Abilita Miei (Normali)
	for container in enable_list:
		for btn in container.get_children():
			btn.focus_mode = Control.FOCUS_ALL
			btn.disabled = false
			btn.modulate.a = 1.0

func _force_initial_focus():
	await get_tree().process_frame
	await get_tree().process_frame 
	
	var target_list = home_starters_list if _user_side == "home" else away_starters_list
	
	if target_list.get_child_count() > 0:
		target_list.get_child(0).grab_focus()

func _restore_focus_to_id(target_id: int):
	await get_tree().process_frame
	
	var containers = [home_starters_list, home_bench_list, away_starters_list, away_bench_list]
	
	for c in containers:
		for btn in c.get_children():
			if "player_id" in btn and btn.player_id == target_id:
				btn.grab_focus()
				return


# ==============================================================================
#  UTILITY
# ==============================================================================

func get_complete_surname(full_name: String) -> String:
	var first_space = full_name.find(" ")
	if first_space == -1: return full_name
	return full_name.substr(first_space + 1)

func _update_formation_texture(starters: Array, tex_rect: TextureRect):
	var def = 0; var mid = 0; var fwd = 0
	for p in starters:
		var r = p.get("Position", p.get("Role", "A"))
		if r == "D": def += 1
		elif r == "C": mid += 1
		elif r == "A": fwd += 1
	
	var path = "res://Images/Formations/%d-%d-%d.png" % [def, mid, fwd]
	if FileAccess.file_exists(path): tex_rect.texture = load(path)

func _on_start_match_pressed():
	print("🚀 Avvio Partita RPG...")
	get_tree().change_scene_to_file("res://Scenes/MatchRPG.tscn")
