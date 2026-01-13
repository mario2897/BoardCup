class_name TurnManager
extends Node

# Stati del turno
enum State { SETUP, WAIT_BASE_VOTE, WAIT_FINAL_VOTE, END_MATCH }
var current_state = State.SETUP

# --- DATI PARTITA ---
var home_team_id: int
var away_team_id: int
var home_kit: String
var away_kit: String

# Coda Giocatori
var action_queue: Array = [] 
var current_player_data: Dictionary
var is_current_player_home: bool = false

# Dati temporanei
var _temp_base_vote: float = 0.0
var score_home: float = 0.0
var score_away: float = 0.0

func _ready():
	call_deferred("setup_match")

# --- FASE 1: SETUP ---
func setup_match():
	var res = DataManager.select_rows_simple("SELECT HomeTeamID, AwayTeamID, HomeKitPath, AwayKitPath FROM CurrentMatchFantasy WHERE MatchID = 1")
	if res.is_empty(): return
	
	home_team_id = int(res[0]["HomeTeamID"])
	away_team_id = int(res[0]["AwayTeamID"])
	home_kit = res[0].get("HomeKitPath", "")
	away_kit = res[0].get("AwayKitPath", "")
	
	# Setup UI Iniziale
	var match_ui = get_parent()
	if match_ui and match_ui.has_method("setup_match_ui"):
		match_ui.setup_match_ui(home_team_id, away_team_id, home_kit, away_kit)
	
	# Recupera Roster
	var roster_h = DataManager.get_match_roster_starters(home_team_id)
	var roster_a = DataManager.get_match_roster_starters(away_team_id)
	
	for p in roster_h: p["IsFantasyHome"] = true
	for p in roster_a: p["IsFantasyHome"] = false
	
	# Crea Coda Arricchita (Dati Avversario e Percentuali già caricati)
	action_queue = _create_enriched_queue(roster_h, roster_a)
	
	start_next_turn()

func _create_enriched_queue(roster_h: Array, roster_a: Array) -> Array:
	var pool = roster_h + roster_a
	var sorted_queue = []
	
	# Mappa Calendario Reale
	var real_schedule = DataManager.get_real_schedule() 
	var team_schedule_map = {}
	var chrono_teams = [] 

	if not real_schedule.is_empty():
		for m in real_schedule:
			var h = int(m.get("Home_ID", -1))
			var a = int(m.get("Away_ID", -1))
			team_schedule_map[h] = a
			team_schedule_map[a] = h
			chrono_teams.append(h)
			chrono_teams.append(a)

	# Arricchimento Dati Giocatore
	for p in pool:
		var real_team_id = int(p.get("RealTeamID", -1))
		
		# 1. Dati Partita Reale
		if team_schedule_map.has(real_team_id):
			var opp_id = team_schedule_map[real_team_id]
			var opp_data = DataManager.get_team_data(opp_id)
			p["RealOpponentName"] = opp_data.get("Name", "Avversario")
			p["RealOpponentLogoPath"] = opp_data.get("LogoPath", "")
		else:
			p["RealOpponentName"] = "RIPOSO"
			p["RealOpponentLogoPath"] = ""

		# 2. Percentuali Successo (Dal DB)
		var pid = int(p.get("PlayerID"))
		# (Inserisci qui la tua query per SuccessRate se la usi)
		p["SuccessRate"] = 50.0 
		
		p["MatchEvents"] = [] # Inizializza eventi vuoti

	# Ordinamento Cronologico
	if real_schedule.is_empty():
		pool.shuffle()
		return pool

	for team_id_in_order in chrono_teams:
		for k in range(pool.size() - 1, -1, -1):
			var p = pool[k]
			if int(p.get("RealTeamID", -99)) == team_id_in_order:
				sorted_queue.append(p)
				pool.remove_at(k)
	
	if pool.size() > 0: sorted_queue.append_array(pool)
	return sorted_queue

# --- FASE 2: GESTIONE TURNO (MODIFICATA PER DOPPIA CARTA) ---
func start_next_turn():
	if action_queue.is_empty():
		_handle_match_end()
		return
	
	# 1. Estrai Giocatore ATTIVO (rimuovilo dalla coda)
	current_player_data = action_queue.pop_front()
	is_current_player_home = current_player_data["IsFantasyHome"]
	current_state = State.WAIT_BASE_VOTE
	
	# 2. Trova il prossimo Giocatore IN ATTESA (Senza rimuoverlo!)
	# Cerchiamo il prossimo della squadra avversaria
	var next_opponent_data = _peek_next_player(!is_current_player_home)
	
	# 3. Aggiorna UI con ENTRAMBI i dati
	var match_ui = get_parent()
	if match_ui and match_ui.has_method("update_match_cards"):
		var active_kit = home_kit if is_current_player_home else away_kit
		var opp_kit = away_kit if is_current_player_home else home_kit
		
		match_ui.update_match_cards(
			current_player_data, 
			next_opponent_data, 
			is_current_player_home,
			active_kit,
			opp_kit
		)
		
		# Evidenzia pedina
		var field = match_ui.find_child("FantasyFieldManager", true, false)
		if field: field.highlight_active_player(int(current_player_data["PlayerID"]))

# Helper per cercare nella coda futura
func _peek_next_player(want_home: bool) -> Dictionary:
	for p in action_queue:
		if p.get("IsFantasyHome") == want_home:
			return p
	return {} # Nessuno trovato

# --- FASE 3: INPUT ---
func _input(event):
	if event.is_action_pressed("ui_accept"):
		match current_state:
			State.WAIT_BASE_VOTE:
				_step_1_calculate_base()
			State.WAIT_FINAL_VOTE:
				_step_2_calculate_final()

func _step_1_calculate_base():
	var base = float(current_player_data.get("PerformanceVote", 6.0))
	var d1 = randi_range(1, 6)
	var d2 = randi_range(1, 6)
	_temp_base_vote = snapped(base + (float(d1 + d2) / 4.0), 0.5)
	
	var match_ui = get_parent()
	if match_ui: match_ui.ui_show_base_vote(_temp_base_vote)
	
	# --- AGGIUNTA: Aggiorna anche la lista/campo ---
	var field = get_tree().root.find_child("FantasyField", true, false)
	if field:
		field.update_player_vote(int(current_player_data["PlayerID"]), _temp_base_vote)
	# -----------------------------------------------

	current_state = State.WAIT_FINAL_VOTE

func _step_2_calculate_final():
	var diff = float(current_player_data.get("DifficultyMultiplier", 0.0))
	var final_vote = _temp_base_vote + diff
	
	# A. Mostra Bonus su Carta Grande
	var match_ui = get_parent()
	if match_ui and match_ui.has_method("ui_show_bonus"):
		match_ui.ui_show_bonus(diff)
	
	# B. Aggiorna Voto Finale su Lista Campo <--- NUOVO FIX
	# (Se vuoi che nella lista appaia il voto FINALE, lo aggiorniamo qui)
	var field = get_tree().root.find_child("FantasyFieldManager", true, false)
	if field:
		field.update_player_vote(int(current_player_data["PlayerID"]), final_vote)

	# Passa al prossimo turno dopo un breve delay (o subito)
	await get_tree().create_timer(1.0).timeout
	start_next_turn()

func _handle_match_end():
	print("🏆 FINE PARTITA")
	current_state = State.END_MATCH
