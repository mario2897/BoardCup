class_name FantasyFieldManager
extends Control

# LA SCENA PREFAB (Trascina qui "PlayerDot.tscn")
@export var player_dot_scene: PackedScene 

# --- RIFERIMENTI AI CONTAINER (Come da tuo script originale) ---
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
	
	# 2. RECUPERA COLORI AVANZATI (Primario/Secondario) DAL DB
	# true = Kit Casa, false = Kit Trasferta
	var cols_home = DataManager.get_team_colors_full(home_id, true, h_kit)
	var cols_away = DataManager.get_team_colors_full(away_id, false, a_kit)
	
	print("🎨 Colori Casa: ", cols_home)
	print("🎨 Colori Ospiti: ", cols_away)
	
	# 3. Spawna le pedine passando i colori
	_spawn_team(home_roster, true, cols_home)
	_spawn_team(away_roster, false, cols_away)

func _spawn_team(roster_data: Array, is_home: bool, colors: Dictionary):
	for player_data in roster_data:
		# Gestione Ruolo (gestisce sia 'Position' che 'Role')
		var role = player_data.get("Position", player_data.get("Role", "A"))
		
		var container = _get_target_container(is_home, role)
		
		if container:
			var dot = player_dot_scene.instantiate()
			container.add_child(dot)
			
			# --- SETUP PEDINA (COLORI E DATI) ---
			if dot.has_method("setup"):
				# Passiamo Primario e Secondario estratti dal DB
				dot.setup(player_data, colors["primary"], colors["secondary"])
			
			# Salviamo il riferimento per l'evidenziazione del turno
			var pid = int(player_data.get("PlayerID"))
			spawned_players[pid] = dot
		else:
			print("⚠️ Container non trovato per ruolo: ", role)

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

# --- NUOVO: Funzione chiamata dal TurnManager per evidenziare chi gioca ---
func highlight_active_player(player_id: int):
	# 1. Spegni tutti
	for pid in spawned_players:
		if is_instance_valid(spawned_players[pid]):
			spawned_players[pid].highlight(false)
	
	# 2. Accendi quello giusto
	if spawned_players.has(player_id):
		if is_instance_valid(spawned_players[player_id]):
			spawned_players[player_id].highlight(true)
