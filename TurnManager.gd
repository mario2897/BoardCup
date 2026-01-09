class_name TurnManager
extends Node

enum State { SETUP, WAIT_INPUT, ROLLING, NEXT_PLAYER, END_MATCH }
var current_state = State.SETUP

# --- RIFERIMENTI ---
@export var active_card_home: Node # Riferimenti opzionali se ancora usati, altrimenti ignorali
@export var active_card_away: Node

# --- DATI ---
var home_team_id: int
var away_team_id: int
var action_queue: Array = [] 
var current_player_data: Dictionary
var is_current_player_home: bool = false
var score_home: float = 0.0
var score_away: float = 0.0

func _ready():
	call_deferred("setup_match")

func setup_match():
	print("\n--- TURN MANAGER: SETUP ---")
	
	# 1. Recupera Dati Partita (per sapere chi gioca)
	var res = DataManager.select_rows_simple("SELECT HomeTeamID, AwayTeamID FROM CurrentMatchFantasy WHERE MatchID = 1")
	if res.is_empty(): return
	
	home_team_id = int(res[0]["HomeTeamID"])
	away_team_id = int(res[0]["AwayTeamID"])
	
	# 2. Recupera Roster
	var roster_h = DataManager.get_match_roster_starters(home_team_id)
	var roster_a = DataManager.get_match_roster_starters(away_team_id)
	
	# 3. Assegna appartenenza
	for p in roster_h: p["IsFantasyHome"] = true
	for p in roster_a: p["IsFantasyHome"] = false
	
	# 4. Crea la coda ordinata cronologicamente
	action_queue = _create_chronological_queue(roster_h, roster_a)
	
	# 5. Avvia il primo turno
	start_next_turn()

func _create_chronological_queue(roster_h: Array, roster_a: Array) -> Array:
	var sorted_queue = []
	var pool = roster_h + roster_a
	var real_schedule = DataManager.get_real_schedule()
	
	# Se non c'è calendario reale, mischia a caso
	if real_schedule.is_empty():
		pool.shuffle()
		return pool

	# Algoritmo di ordinamento basato sul calendario reale
	for i in range(real_schedule.size()):
		var match_real = real_schedule[i]
		var real_h_id = int(match_real.get("Home_ID", -1))
		var real_a_id = int(match_real.get("Away_ID", -1))
		
		var players_found = []
		for k in range(pool.size() - 1, -1, -1):
			var p = pool[k]
			var p_real_id = int(p.get("RealTeamID", -99))
			
			if p_real_id == real_h_id or p_real_id == real_a_id:
				players_found.append(p)
				pool.remove_at(k)
		
		for p in players_found:
			sorted_queue.append(p)

	if pool.size() > 0:
		for p in pool: sorted_queue.append(p)
			
	return sorted_queue

func start_next_turn():
	if action_queue.is_empty():
		print("FINE PARTITA")
		current_state = State.END_MATCH
		return
	
	current_state = State.WAIT_INPUT
	current_player_data = action_queue.pop_front()
	is_current_player_home = current_player_data["IsFantasyHome"]

func _unhandled_input(event):
	if current_state == State.WAIT_INPUT and event.is_action_pressed("ui_accept"):
		perform_roll()

func perform_roll():
	current_state = State.ROLLING
	var d1 = randi_range(1, 6)
	var d2 = randi_range(1, 6)
	
	var base = float(current_player_data.get("PerformanceVote", 6.0))
	var diff = int(current_player_data.get("DifficultyMultiplier", 0))
	var tot = base + (float(d1 + d2 + diff) / 2.0)
	
	if is_current_player_home: score_home += tot
	else: score_away += tot
	
	print("🎲 %s -> Tiro: %d+%d -> Tot: %.1f" % [current_player_data.get("Name"), d1, d2, tot])
	
	# --- COMUNICAZIONE CON LA UI (MatchFantasy) ---
	var match_node = get_parent()
	if match_node:
		# 1. Aggiorna Voto sulla targhetta del giocatore
		var pid = int(current_player_data.get("PlayerID", 0))
		if match_node.has_method("update_player_vote_ui"):
			match_node.update_player_vote_ui(pid, tot)
		
		# 2. Aggiorna Scoreboard Totale
		if match_node.has_method("update_scoreboard"):
			match_node.update_scoreboard(score_home, score_away)
	
	await get_tree().create_timer(1.0).timeout
	start_next_turn()
