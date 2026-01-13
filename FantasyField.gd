class_name FantasyField
extends Control

# LA SCENA PREFAB (Trascina qui "PlayerDot.tscn")
@export var player_dot_scene: PackedScene 

# --- RIFERIMENTI AI CONTAINER ---
@onready var home_gk = $Pitch/VSplitContainer/HomeTeam/GoalKeeper
@onready var home_def = $Pitch/VSplitContainer/HomeTeam/Defenders
@onready var home_mid = $Pitch/VSplitContainer/HomeTeam/Midfielders
@onready var home_str = $Pitch/VSplitContainer/HomeTeam/Strikers

@onready var away_gk = $Pitch/VSplitContainer/AwayTeam/GoalKeeper
@onready var away_def = $Pitch/VSplitContainer/AwayTeam/Defenders
@onready var away_mid = $Pitch/VSplitContainer/AwayTeam/Midfielders
@onready var away_str = $Pitch/VSplitContainer/AwayTeam/Strikers

# Dizionario per tracciare le pedine create: { player_id : node }
var spawned_players = {}

func _ready():
	_clear_field()
	
	if not player_dot_scene:
		printerr("❌ ERRORE: 'Player Dot Scene' non assegnata nell'Inspector!")
		return
	
	# 1. Recuperiamo Dati Partita dal DB
	var query = "SELECT HomeTeamID, AwayTeamID, HomeKitPath, AwayKitPath FROM CurrentMatchFantasy WHERE MatchID = 1"
	var res = DataManager.select_rows_simple(query)
	
	if res.size() > 0:
		var home_id = int(res[0]["HomeTeamID"])
		var away_id = int(res[0]["AwayTeamID"])
		var h_kit = res[0].get("HomeKitPath", "")
		var a_kit = res[0].get("AwayKitPath", "")
		
		print("✅ Setup Campo: Home %d vs Away %d" % [home_id, away_id])
		setup_field(home_id, away_id, h_kit, a_kit)
	else:
		printerr("⚠️ NESSUNA PARTITA TROVATA (MatchID 1)")

func setup_field(home_id: int, away_id: int, h_kit: String, a_kit: String):
	_clear_field()
	spawned_players.clear()

	# 1. Recupera i roster (Titolari)
	var home_roster = DataManager.get_match_roster_starters(home_id)
	var away_roster = DataManager.get_match_roster_starters(away_id)
	
	# 2. RECUPERA COLORI AVANZATI (DINAMICI)
	# Controlliamo se la maglia attuale corrisponde a quella di casa nel DB
	var is_home_wearing_home = _check_is_default_home_kit(home_id, h_kit)
	var is_away_wearing_home = _check_is_default_home_kit(away_id, a_kit)
	
	# Passiamo il risultato booleano corretto invece di true/false fissi
	var cols_home = DataManager.get_team_colors_full(home_id, is_home_wearing_home, h_kit)
	var cols_away = DataManager.get_team_colors_full(away_id, is_away_wearing_home, a_kit)
	
	print("🎨 Colori Casa (Kit Home? %s): %s" % [is_home_wearing_home, cols_home])
	print("🎨 Colori Ospiti (Kit Home? %s): %s" % [is_away_wearing_home, cols_away])
	
	# 3. Spawna le pedine passando i colori
	_spawn_team(home_roster, true, cols_home)
	_spawn_team(away_roster, false, cols_away)

func _spawn_team(roster_data: Array, is_home: bool, colors: Dictionary):
	for player_data in roster_data:
		# Gestione Ruolo
		var role = player_data.get("Position", player_data.get("Role", "A"))
		var container = _get_target_container(is_home, role)
		
		if container:
			var dot = player_dot_scene.instantiate()
			container.add_child(dot)
			
			# --- SETUP PEDINA ---
			if dot.has_method("setup"):
				dot.setup(player_data, colors["primary"], colors["secondary"])
			
			# Salviamo il riferimento
			var pid = int(player_data.get("PlayerID"))
			spawned_players[pid] = dot

func _get_target_container(is_home: bool, role: String) -> BoxContainer:
	if is_home:
		match role:
			"P", "GK": return home_gk
			"D", "DEF": return home_def
			"C", "MID": return home_mid
			"A", "ATT": return home_str
	else:
		match role:
			"P", "GK": return away_gk
			"D", "DEF": return away_def
			"C", "MID": return away_mid
			"A", "ATT": return away_str
	return null

func _clear_field():
	spawned_players.clear()
	var all = [home_gk, home_def, home_mid, home_str, away_gk, away_def, away_mid, away_str]
	for c in all:
		if c: 
			for child in c.get_children(): 
				child.queue_free()

func highlight_active_player(player_id: int):
	for pid in spawned_players:
		if is_instance_valid(spawned_players[pid]):
			spawned_players[pid].highlight(false)
	
	if spawned_players.has(player_id):
		if is_instance_valid(spawned_players[player_id]):
			spawned_players[player_id].highlight(true)

# --- NUOVA FUNZIONE DI CONTROLLO ---
func _check_is_default_home_kit(team_id: int, current_path: String) -> bool:
	var team_data = DataManager.get_fantasy_team_data(team_id)
	if team_data:
		var default_home = team_data.get("HomeKitPath", "")
		# Se il percorso attuale coincide con quello di casa nel DB, ritorna true
		if current_path == default_home: return true
	return false

func update_player_vote(player_id: int, vote_value: float):
	# Controlliamo se abbiamo generato questo giocatore
	if spawned_players.has(player_id):
		var player_node = spawned_players[player_id]
		
		# Se il nodo è valido e ha la funzione che abbiamo creato prima
		if is_instance_valid(player_node) and player_node.has_method("show_vote_result"):
			player_node.show_vote_result(vote_value)
