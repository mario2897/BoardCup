extends Control

# --- RIFERIMENTI ---
@onready var scoreboard = $PanelContainer/MatchLayout/MatchInfo/FantasyScoreboard

@onready var h_lbl_starters = $PanelContainer/MatchLayout/HomeTeam/Starters
@onready var h_list_starters = $PanelContainer/MatchLayout/HomeTeam/StartersList
@onready var h_lbl_bench = $PanelContainer/MatchLayout/HomeTeam/Bench
@onready var h_list_bench = $PanelContainer/MatchLayout/HomeTeam/BenchList
@onready var h_active_overlay = $PanelContainer/MatchLayout/HomeTeam/HomeActivePlayerCard

@onready var a_lbl_starters = $PanelContainer/MatchLayout/AwayTeam/Starters
@onready var a_list_starters = $PanelContainer/MatchLayout/AwayTeam/StartersList
@onready var a_lbl_bench = $PanelContainer/MatchLayout/AwayTeam/Bench
@onready var a_list_bench = $PanelContainer/MatchLayout/AwayTeam/BenchList
@onready var a_active_overlay = $PanelContainer/MatchLayout/AwayTeam/AwayActivePlayerCard

var nametag_scene = preload("res://Scenes/Prefabs/PlayerMatchNametag.tscn")
var _nametag_map: Dictionary = {}

var _home_colors: Dictionary = {}
var _away_colors: Dictionary = {}

func _ready():
	_nametag_map.clear()
	# Inizialmente nascondi o sbiadisci
	if h_active_overlay: h_active_overlay.modulate.a = 0.0
	if a_active_overlay: a_active_overlay.modulate.a = 0.0

# --- SETUP INIZIALE ---
func setup_match_ui(home_id: int, away_id: int, home_kit: String, away_kit: String):
	print("⚽ UI SETUP...")
	
	var home_data = DataManager.get_fantasy_team_data(home_id)
	var away_data = DataManager.get_fantasy_team_data(away_id)
	
	var is_h_def = _check_is_default_home_kit(home_id, home_kit)
	var is_a_def = _check_is_default_home_kit(away_id, away_kit)
	
	_home_colors = DataManager.get_team_colors_full(home_id, is_h_def, home_kit)
	_away_colors = DataManager.get_team_colors_full(away_id, is_a_def, away_kit)
	
	home_data["PrimaryColor"] = _home_colors["primary"]
	home_data["SecondaryColor"] = _home_colors["secondary"]
	away_data["PrimaryColor"] = _away_colors["primary"]
	away_data["SecondaryColor"] = _away_colors["secondary"]
	
	if scoreboard: scoreboard.setup_match(home_data, away_data)
	
	_setup_lists(home_id, _home_colors, h_lbl_starters, h_list_starters, h_lbl_bench, h_list_bench)
	_setup_lists(away_id, _away_colors, a_lbl_starters, a_list_starters, a_lbl_bench, a_list_bench)
	
	# Assicurati che le carte siano pronte
	if h_active_overlay and h_active_overlay.has_method("reset_card"): h_active_overlay.reset_card()
	if a_active_overlay and a_active_overlay.has_method("reset_card"): a_active_overlay.reset_card()

# --- FUNZIONE CHIAVE: AGGIORNA ENTRAMBE LE CARTE ---
func update_match_cards(active_data: Dictionary, waiting_data: Dictionary, active_is_home: bool, active_kit: String, waiting_kit: String):
	
	# 1. Definisci UI Attiva e In Attesa
	var active_ui = h_active_overlay if active_is_home else a_active_overlay
	var waiting_ui = a_active_overlay if active_is_home else h_active_overlay
	
	var active_col = _home_colors if active_is_home else _away_colors
	var waiting_col = _away_colors if active_is_home else _home_colors
	
	# 2. CONFIGURA CARTA ATTIVA (Visibile, Opaca, Dati Attivi)
	if active_ui:
		active_ui.visible = true
		active_ui.modulate.a = 1.0
		if active_ui.has_method("setup"):
			active_ui.setup(active_data, active_kit, active_col)
	
	# 3. CONFIGURA CARTA IN ATTESA (Visibile, Sbiadita, Dati Avversario)
	if waiting_ui:
		if waiting_data.is_empty():
			# Nessun avversario rimasto (fine turni per quella squadra)
			waiting_ui.visible = false 
		else:
			waiting_ui.visible = true
			waiting_ui.modulate.a = 0.5 # EFFETTO "INATTIVO" MA VISIBILE
			if waiting_ui.has_method("setup"):
				waiting_ui.setup(waiting_data, waiting_kit, waiting_col)

# --- GESTIONE VOTI ---
func ui_show_base_vote(vote: float):
	var target = h_active_overlay if h_active_overlay.modulate.a > 0.9 else a_active_overlay
	if target and target.has_method("reveal_base_vote"):
		target.reveal_base_vote(vote)

func ui_show_final_result(bonus: float, total: float, event_text: String = ""):
	var target = h_active_overlay if h_active_overlay.modulate.a > 0.9 else a_active_overlay
	if target and target.has_method("reveal_final_outcome"):
		target.reveal_final_outcome(bonus, total, event_text)

func update_scoreboard(h, a):
	if scoreboard: scoreboard.update_scores(h, a)

func update_player_vote_ui(pid, vote):
	var pid_int = int(pid)
	# Controlla se abbiamo la targhetta di questo giocatore nella mappa
	if _nametag_map.has(pid_int):
		var nametag = _nametag_map[pid_int]
		# Chiama la funzione 'show_vote_result' che abbiamo aggiunto al Nametag
		if nametag and nametag.has_method("show_vote_result"):
			nametag.show_vote_result(vote)

# --- HELPERS ---
func _check_is_default_home_kit(tid, path):
	var d = DataManager.get_fantasy_team_data(tid)
	return path == d.get("HomeKitPath", "") if d else true

func _setup_lists(tid, cols, lbl, lst, lbl_b, lst_b):
	_color_lbl(lbl, cols)
	_color_lbl(lbl_b, cols)
	_pop_lst(lst, DataManager.get_match_roster_starters(tid), cols)
	_pop_lst(lst_b, DataManager.get_match_roster_bench(tid), cols)

func _color_lbl(lbl, cols):
	if lbl:
		lbl.add_theme_color_override("font_color", cols["primary"])
		var s = StyleBoxFlat.new()
		s.bg_color = cols["secondary"]
		lbl.add_theme_stylebox_override("normal", s)

func _pop_lst(cont, data, cols):
	for c in cont.get_children(): c.queue_free()
	for p in data:
		if nametag_scene:
			var n = nametag_scene.instantiate()
			cont.add_child(n)
			if n.has_method("setup"): n.setup(p, cols)
			_nametag_map[int(p.get("PlayerID", 0))] = n
