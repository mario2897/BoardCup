class_name TurnManager
extends Node

enum State { SETUP, WAIT_INPUT, ROLLING, NEXT_PLAYER, END_MATCH }
var current_state = State.SETUP

# --- RIFERIMENTI ---
@export_group("Carte Giocatori")
@export var active_card_home: ActivePlayerCard
@export var active_card_away: ActivePlayerCard

# --- DATI ---
var home_team_id: int
var away_team_id: int
var home_kit: String
var away_kit: String

var action_queue: Array = [] 
var current_player_data: Dictionary
var is_current_player_home: bool = false
var score_home: float = 0.0
var score_away: float = 0.0

func _ready():
	call_deferred("setup_match")

func setup_match():
	print("\n--- TURN MANAGER: SETUP ---")
	
	# 1. Recupera Dati Partita
	var res = DataManager.select_rows_simple("SELECT HomeTeamID, AwayTeamID, HomeKitPath, AwayKitPath FROM CurrentMatchFantasy WHERE MatchID = 1")
	if res.is_empty(): return
	
	home_team_id = int(res[0]["HomeTeamID"])
	away_team_id = int(res[0]["AwayTeamID"])
	home_kit = res[0].get("HomeKitPath", "")
	away_kit = res[0].get("AwayKitPath", "")
	
	# 2. Recupera Roster
	var roster_h = DataManager.get_match_roster_starters(home_team_id)
	var roster_a = DataManager.get_match_roster_starters(away_team_id)
	
	# 3. Assegna appartenenza Fantasy (Casa/Trasferta)
	for p in roster_h: p["IsFantasyHome"] = true
	for p in roster_a: p["IsFantasyHome"] = false
	
	# 4. Crea la coda ordinata e STAMPA IL LOG richiesto
	action_queue = _create_chronological_queue(roster_h, roster_a)
	
	# 5. Avvia il primo turno
	start_next_turn()

# --- LOGICA ORDINAMENTO E STAMPA DEBUG ---
func _create_chronological_queue(roster_h: Array, roster_a: Array) -> Array:
	var sorted_queue = []
	var pool = roster_h + roster_a # Uniamo tutti i giocatori
	
	# Recupera il calendario reale salvato in DataManager
	var real_schedule = DataManager.get_real_schedule()
	
	if real_schedule.is_empty():
		print("⚠️ Nessun calendario reale trovato. Uso ordine casuale.")
		pool.shuffle()
		return pool

	print("\n=== CRONACA TURNI CALCOLATA ===")

	# Itera su ogni partita reale del calendario
	for i in range(real_schedule.size()):
		var match_real = real_schedule[i]
		
		var real_h_id = int(match_real.get("Home_ID", -1))
		var real_a_id = int(match_real.get("Away_ID", -1))
		
		# Recupera i NOMI delle squadre reali per il print (Lombardia, Larium, ecc.)
		var team_h_data = DataManager.get_team_data(real_h_id)
		var team_a_data = DataManager.get_team_data(real_a_id)
		var name_h = team_h_data.Name if team_h_data else "Team " + str(real_h_id)
		var name_a = team_a_data.Name if team_a_data else "Team " + str(real_a_id)
		
		# --- PRINT INTESTAZIONE PARTITA ---
		print("PARTITA %d: %s - %s" % [i + 1, name_h.to_upper(), name_a.to_upper()])
		print("GIOCATORI:")
		
		# Cerca i giocatori nel pool che appartengono a queste squadre
		var players_found_in_match = []
		
		# Ciclo inverso per rimuovere dal pool
		for k in range(pool.size() - 1, -1, -1):
			var p = pool[k]
			var p_real_id = int(p.get("RealTeamID", -99))
			
			if p_real_id == real_h_id or p_real_id == real_a_id:
				players_found_in_match.append(p)
				pool.remove_at(k)
		
		# Se non ci sono giocatori fantasy coinvolti in questa partita reale
		if players_found_in_match.is_empty():
			print("(Nessun giocatore fantasy coinvolto)")
		else:
			# Aggiungiamo alla coda ordinata e stampiamo
			for p in players_found_in_match:
				sorted_queue.append(p)
				
				# --- PRINT GIOCATORE ---
				var side = "Casa" if p["IsFantasyHome"] else "Trasferta"
				print("%s %s" % [p["Name"], side])
		
		print("--------------------------------") # Separatore visivo

	# Gestione giocatori residui (non trovati nel calendario)
	if pool.size() > 0:
		print("\nGIOCATORI EXTRA (NON IN CALENDARIO):")
		for p in pool:
			sorted_queue.append(p)
			var side = "Casa" if p["IsFantasyHome"] else "Trasferta"
			print("%s %s," % [p["Name"], side])
			
	return sorted_queue

func start_next_turn():
	if action_queue.is_empty():
		print("FINE PARTITA")
		return
	
	current_state = State.WAIT_INPUT
	current_player_data = action_queue.pop_front()
	is_current_player_home = current_player_data["IsFantasyHome"]
	
	_update_active_cards()

func _update_active_cards():
	# 1. Resetta le carte
	if active_card_home: active_card_home.reset_card()
	if active_card_away: active_card_away.reset_card()
	
	# 2. Forza le divise visibili (richiede set_kit_texture in ActivePlayerCard)
	if active_card_home: active_card_home.set_kit_texture(home_kit)
	if active_card_away: active_card_away.set_kit_texture(away_kit)
	
	# 3. Setup dati sulla carta attiva
	var target = active_card_home if is_current_player_home else active_card_away
	var kit = home_kit if is_current_player_home else away_kit
	
	if target:
		target.setup(current_player_data, kit)

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
	
	print("🎲 Tiro: %d+%d (Diff %d) -> Voto: %.1f | Parziale: %.1f - %.1f" % [d1, d2, diff, tot, score_home, score_away])
	
	await get_tree().create_timer(1.0).timeout
	start_next_turn()
