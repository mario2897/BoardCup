extends Control

# --- RIFERIMENTI UI HOME ---
#@onready var h_header_panel = $PanelContainer/MatchLayout/HomeTeam/HeaderPanel
#@onready var h_lbl_name = $PanelContainer/MatchLayout/HomeTeam/HeaderPanel/VBox/TeamNameLabel
#@onready var h_lbl_score = $PanelContainer/MatchLayout/HomeTeam/HeaderPanel/VBox/ScoreLabel

@onready var h_lbl_starters = $PanelContainer/MatchLayout/HomeTeam/Starters
@onready var h_list_starters = $PanelContainer/MatchLayout/HomeTeam/StartersList
@onready var h_lbl_bench = $PanelContainer/MatchLayout/HomeTeam/Bench
@onready var h_list_bench = $PanelContainer/MatchLayout/HomeTeam/BenchList

# --- RIFERIMENTI UI AWAY ---
#@onready var a_header_panel = $PanelContainer/MatchLayout/AwayTeam/HeaderPanel
#@onready var a_lbl_name = $PanelContainer/MatchLayout/AwayTeam/HeaderPanel/VBox/TeamNameLabel
#@onready var a_lbl_score = $PanelContainer/MatchLayout/AwayTeam/HeaderPanel/VBox/ScoreLabel

@onready var a_lbl_starters = $PanelContainer/MatchLayout/AwayTeam/Starters
@onready var a_list_starters = $PanelContainer/MatchLayout/AwayTeam/StartersList
@onready var a_lbl_bench = $PanelContainer/MatchLayout/AwayTeam/Bench
@onready var a_list_bench = $PanelContainer/MatchLayout/AwayTeam/BenchList

var nametag_scene = preload("res://Scenes/Prefabs/PlayerMatchNametag.tscn")

# Dizionario per ritrovare velocemente la targhetta dato l'ID del giocatore
# Struttura: { player_id (int) : nodo_targhetta (Control) }
var _nametag_map: Dictionary = {}

func _ready():
	_nametag_map.clear()
	setup_match_ui()
	# Inizializza il punteggio a 0-0
	#update_scoreboard(0.0, 0.0)

func setup_match_ui():
	print("⚽ MATCH FANTASY: Setup Scoreboard e Liste...")
	
	var query = "SELECT HomeTeamID, AwayTeamID, HomeKitPath, AwayKitPath FROM CurrentMatchFantasy WHERE MatchID = 1"
	var res = DataManager.select_rows_simple(query)
	if res.is_empty(): return
	
	var home_id = int(res[0]["HomeTeamID"])
	var away_id = int(res[0]["AwayTeamID"])
	var home_kit_path = res[0].get("HomeKitPath", "")
	var away_kit_path = res[0].get("AwayKitPath", "")
	
	# Check Divise: Capisce se la squadra usa la maglia di Casa o Trasferta
	var is_home_def = _check_is_default_home_kit(home_id, home_kit_path)
	var is_away_def = _check_is_default_home_kit(away_id, away_kit_path)
	
	# Recupera Colori (Passiamo il risultato del check per avere i colori giusti)
	var cols_h = DataManager.get_team_colors_full(home_id, is_home_def, home_kit_path)
	var cols_a = DataManager.get_team_colors_full(away_id, is_away_def, away_kit_path)
	
	# Recupera Nomi Squadre
	var home_data = DataManager.get_fantasy_team_data(home_id)
	var away_data = DataManager.get_fantasy_team_data(away_id)
	var home_name = home_data.Name if home_data else "Home Team"
	var away_name = away_data.Name if away_data else "Away Team"
	
	# --- SETUP UI CASA ---
	#_setup_header(h_header_panel, h_lbl_name, h_lbl_score, home_name, cols_h)
	_setup_lists(home_id, cols_h, h_lbl_starters, h_list_starters, h_lbl_bench, h_list_bench)
	
	# --- SETUP UI TRASFERTA ---
	#_setup_header(a_header_panel, a_lbl_name, a_lbl_score, away_name, cols_a)
	_setup_lists(away_id, cols_a, a_lbl_starters, a_list_starters, a_lbl_bench, a_list_bench)

# Configura l'intestazione col nome squadra e il punteggio
#func _setup_header(panel: PanelContainer, lbl_name: Label, lbl_score: Label, team_name: String, colors: Dictionary):
	# 1. Stile Pannello (Sfondo Primario)
	#var style = StyleBoxFlat.new()
	#style.bg_color = colors["primary"]
	#style.border_width_bottom = 4
	#style.border_color = colors["secondary"]
	#style.corner_radius_top_left = 8
	#style.corner_radius_top_right = 8
	#panel.add_theme_stylebox_override("panel", style)
	
	# 2. Testi (Colore Secondario)
	#lbl_name.text = team_name.to_upper()
	#lbl_name.add_theme_color_override("font_color", colors["secondary"])
	#lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	#lbl_name.add_theme_font_size_override("font_size", 24)
	
	#lbl_score.text = "0.0 - 0 GOL"
	#lbl_score.add_theme_color_override("font_color", colors["secondary"])
	#lbl_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	#lbl_score.add_theme_font_size_override("font_size", 16)

# Aggiorna il testo dello scoreboard totale
#func update_scoreboard(score_h: float, score_a: float):
	#var goals_h = _calculate_goals(score_h)
	#var goals_a = _calculate_goals(score_a)
	
	#h_lbl_score.text = "%.1f - %d GOL" % [score_h, goals_h]
	#a_lbl_score.text = "%.1f - %d GOL" % [score_a, goals_a]

# Calcola i gol in base alle fasce (es. <66 = 0, >=66 = 1, ogni 6pt un altro gol)
func _calculate_goals(total_score: float) -> int:
	if total_score < 66.0: return 0
	if total_score < 72.0: return 1
	if total_score < 78.0: return 2
	if total_score < 84.0: return 3
	if total_score < 90.0: return 4
	if total_score < 96.0: return 5
	return 6 + int((total_score - 96) / 6)

# Verifica se si sta usando la divisa di casa predefinita
func _check_is_default_home_kit(team_id: int, current_path: String) -> bool:
	var team_data = DataManager.get_fantasy_team_data(team_id)
	if team_data:
		var default_home = team_data.get("HomeKitPath", "")
		if current_path != default_home: return false
	return true

# Funzione helper per popolare liste e labels
func _setup_lists(team_id: int, colors: Dictionary, lbl_start: Label, list_start: VBoxContainer, lbl_bench: Label, list_bench: VBoxContainer):
	_apply_colors_to_label(lbl_start, colors)
	_apply_colors_to_label(lbl_bench, colors)
	
	var starters = DataManager.get_match_roster_starters(team_id)
	_populate_list(list_start, starters, colors)
	
	var bench = DataManager.get_match_roster_bench(team_id)
	_populate_list(list_bench, bench, colors)

# Applica lo stile alle etichette "TITOLARI" / "PANCHINA"
func _apply_colors_to_label(label: Label, colors: Dictionary):
	# Testo -> Primario
	label.add_theme_color_override("font_color", colors["primary"])
	# Sfondo -> Secondario
	var style = StyleBoxFlat.new()
	style.bg_color = colors["secondary"]
	label.add_theme_stylebox_override("normal", style)

# Crea le targhette e le salva nel dizionario
func _populate_list(container: VBoxContainer, roster: Array, colors: Dictionary):
	for c in container.get_children(): c.queue_free()
	
	for p_data in roster:
		if nametag_scene:
			var card = nametag_scene.instantiate()
			container.add_child(card)
			card.setup(p_data, colors)
			
			# SALVIAMO IL RIFERIMENTO
			var pid = int(p_data.get("PlayerID", 0))
			_nametag_map[pid] = card

# --- FUNZIONE CHIAMATA DAL TURN MANAGER ---
# Aggiorna il voto sulla targhetta specifica
func update_player_vote_ui(player_id: int, vote_value: float):
	if _nametag_map.has(player_id):
		_nametag_map[player_id].update_score("%.1f" % vote_value)
