extends Node

# -----------------------------------------------------------------------------
# 1. GESTIONE CONNESSIONE DATABASE
# -----------------------------------------------------------------------------
var db
const DB_PATH = "res://Goal!Quest.sqlite"

# CACHE PER IL CALENDARIO REALE (Usata dal TurnManager per l'ordine dei turni)
var _current_real_schedule: Array = []

func _ready():
	if not FileAccess.file_exists(DB_PATH):
		printerr("ERRORE CRITICO: Database non trovato in ", DB_PATH)
		return

	db = SQLite.new() # Assicurati di avere il plugin Godot-SQLite attivo
	db.path = DB_PATH
	db.open_db()
	print("✅ DataManager: Connesso al DB.")
	
	# Carica le regole dei dadi in memoria per velocità
	load_all_rules()

# Wrapper pubblico per eseguire query semplici (usato dagli altri script)
func select_rows_simple(query: String) -> Array:
	return _esegui_query(query)

# Funzione interna per query sicure
func _esegui_query(query: String, bindings: Array = []):
	var success = db.query_with_bindings(query, bindings)
	if not success:
		printerr("❌ ERRORE SQL: ", query)
		printerr("👉 ", db.get_error_message())
		return []
	return db.get_query_result()

# -----------------------------------------------------------------------------
# 2. GESTIONE CALENDARIO REALE (Per TurnManager)
# -----------------------------------------------------------------------------

# Chiama questa funzione da StartersSelection quando generi la giornata!
func set_real_schedule(schedule: Array):
	_current_real_schedule = schedule
	print("📅 DataManager: Salvato ordine cronologico di %d partite reali." % schedule.size())

func get_real_schedule() -> Array:
	return _current_real_schedule

# -----------------------------------------------------------------------------
# 3. LETTURA DATI STATICI (Teams, Players, Leagues)
# -----------------------------------------------------------------------------

func get_all_leagues():
	return _esegui_query("SELECT * FROM Leagues WHERE Visibility = 1 ORDER BY Rating ASC")
	
func get_all_fantasy_teams():
	return _esegui_query("SELECT * FROM FantasyTeams ORDER BY Name ASC")

func get_teams_by_league(league_id: String):
	return _esegui_query("SELECT * FROM Teams WHERE LeagueID = ? AND Visible = 1 ORDER BY Name ASC", [league_id])

func get_team_data(id: int): 
	var res = _esegui_query("SELECT * FROM Teams WHERE TeamID = ?", [id])
	return res[0] if not res.is_empty() else null

func get_fantasy_team_data(id: int): 
	var res = _esegui_query("SELECT * FROM FantasyTeams WHERE TeamID = ?", [id])
	return res[0] if not res.is_empty() else null

func get_player_data(id: int): 
	var res = _esegui_query("SELECT * FROM Players WHERE PlayerID = ?", [id])
	return res[0] if not res.is_empty() else null

# -----------------------------------------------------------------------------
# 4. GESTIONE PARTITA (Inizializzazione e Roster)
# -----------------------------------------------------------------------------
# GENERAZIONE GIORNATA CASUALE (Fondamentale per StartersSelection)
func get_league_matchday(league_id: String) -> Array:
	var query = "WITH RandomizedLeague AS (
		  SELECT 
			TeamID, Name, Abbreviation, LogoPath, Strength,
			ROW_NUMBER() OVER (ORDER BY RANDOM()) as rn
		  FROM Teams WHERE LeagueID = ?
		)
		SELECT 
			H.TeamID AS Home_ID, H.Name AS Home_Name, H.Abbreviation AS Home_Abbr, H.LogoPath AS Home_Logo,
			A.TeamID AS Away_ID, A.Name AS Away_Name, A.Abbreviation AS Away_Abbr, A.LogoPath AS Away_Logo,
			
			-- Calcolo differenza forza (Modificatore Difficoltà)
			(H.Strength - A.Strength) AS Home_Diff,
			(A.Strength - H.Strength) AS Away_Diff
			
		FROM (SELECT * FROM RandomizedLeague WHERE rn % 2 = 1) AS H
		JOIN (SELECT * FROM RandomizedLeague WHERE rn % 2 = 0) AS A ON H.rn + 1 = A.rn
		LIMIT 10"
	return _esegui_query(query, [league_id])

func _get_current_roster_table() -> String:
	# Controlla se esiste GlobalVariables e la modalità
	if get_node_or_null("/root/GlobalVariables") and GlobalVariables.ModalitàPartita == "RPG":
		return "MatchRostersRPG"
	return "MatchRostersFantasy"
	
func swap_match_roster_status(p_id1: int, p_id2: int):
	var table = _get_current_roster_table()
	
	# 1. Recupera lo stato attuale di entrambi
	var q_get = "SELECT IsStarter FROM " + table + " WHERE PlayerID = ?"
	var r1 = _esegui_query(q_get, [p_id1])
	var r2 = _esegui_query(q_get, [p_id2])
	
	if r1.is_empty() or r2.is_empty(): 
		printerr("❌ Errore Swap: Giocatori non trovati nel DB.")
		return
	
	var s1 = r1[0]["IsStarter"]
	var s2 = r2[0]["IsStarter"]
	
	# 2. Scambia e aggiorna
	var q_upd = "UPDATE " + table + " SET IsStarter = ? WHERE PlayerID = ?"
	_esegui_query(q_upd, [s2, p_id1])
	_esegui_query(q_upd, [s1, p_id2])
	
	print("✅ Swap eseguito tra %d e %d" % [p_id1, p_id2])

# A. Inizializzazione Dati Generali Partita
func init_match_data(home_id: int, away_id: int, home_kit: String, away_kit: String):
	var table = "CurrentMatchFantasy" # Default
	if GlobalVariables and GlobalVariables.ModalitàPartita == "RPG": table = "CurrentMatchRPG"
	
	# Reset dati partita
	var query = "UPDATE " + table + " SET HomeTeamID=?, AwayTeamID=?, HomeKitPath=?, AwayKitPath=?, HomeScore=0, AwayScore=0, Status='PRE_MATCH' WHERE MatchID=1"
	_esegui_query(query, [home_id, away_id, home_kit, away_kit])
	
	# Reset contatori
	if table == "CurrentMatchFantasy":
		_esegui_query("UPDATE CurrentMatchFantasy SET RemainingDicesInHalf=11, TotalDicesPerHalf=11 WHERE MatchID=1")
	
	print("✅ Match Data inizializzato su: ", table)

# B. Inizializzazione Roster (LOGICA IBRIDA FANTASY/REALE)
func init_match_roster(home_team_id: int, away_team_id: int, is_fantasy_mode: bool):
	if is_fantasy_mode:
		_esegui_query("DELETE FROM MatchRostersFantasy")
		
		# 1. SQUADRA CASA (Assumiamo Fantasy)
		var q_home = "INSERT INTO MatchRostersFantasy (MatchID, PlayerID, FantasyTeamID, RealTeamID, Name, ShortName, Role, IsStarter, ClassID)
			SELECT 1, FR.PlayerID, FR.FantasyTeamID, P.TeamID, P.Name, P.ShortName, P.Position, FR.IsStarter, P.ClassID
			FROM FantasyRosters FR 
			JOIN Players P ON FR.PlayerID = P.PlayerID
			WHERE FR.FantasyTeamID = ?"
		_esegui_query(q_home, [home_team_id])
		
		# 2. SQUADRA TRASFERTA (Controllo Fantasy o CPU Reale)
		# Tentativo A: Cerca in FantasyRosters
		var q_away_f = "INSERT INTO MatchRostersFantasy (MatchID, PlayerID, FantasyTeamID, RealTeamID, Name, ShortName, Role, IsStarter, ClassID)
			SELECT 1, FR.PlayerID, FR.FantasyTeamID, P.TeamID, P.Name, P.ShortName, P.Position, FR.IsStarter, P.ClassID
			FROM FantasyRosters FR 
			JOIN Players P ON FR.PlayerID = P.PlayerID
			WHERE FR.FantasyTeamID = ?"
		_esegui_query(q_away_f, [away_team_id])
		
		# Verifica se ha inserito qualcosa
		var check = _esegui_query("SELECT count(*) as c FROM MatchRostersFantasy WHERE FantasyTeamID = ?", [away_team_id])
		var count = int(check[0]["c"])
		
		if count == 0:
			print("ℹ️ AwayID %d non trovata in FantasyRosters. Carico come Squadra Reale (CPU)..." % away_team_id)
			# Tentativo B: Carica da Players (Squadra Reale)
			# FantasyTeamID = 0 indica CPU/Reale
			var q_away_r = "INSERT INTO MatchRostersFantasy (MatchID, PlayerID, FantasyTeamID, RealTeamID, Name, ShortName, Role, IsStarter, ClassID)
				SELECT 1, PlayerID, 0, TeamID, Name, ShortName, Position, IsStarter, ClassID
				FROM Players 
				WHERE TeamID = ?"
			_esegui_query(q_away_r, [away_team_id])
			
	else:
		# MODALITÀ RPG (Reale vs Reale)
		_esegui_query("DELETE FROM MatchRostersRPG")
		var query = "INSERT INTO MatchRostersRPG (MatchID, PlayerID, TeamID, Name, ShortName, Role, IsStarter, ClassID, Condition)
			SELECT 1, PlayerID, TeamID, Name, ShortName, Position, IsStarter, ClassID, 100
			FROM Players WHERE TeamID IN (?, ?)"
		_esegui_query(query, [home_team_id, away_team_id])
		
	print("✅ Roster Inizializzato (Home: %d, Away: %d)" % [home_team_id, away_team_id])

# C. Recupero Titolari per TurnManager
func get_match_roster_starters(team_id: int) -> Array:
	var table = _get_current_roster_table()
	var col_team = "FantasyTeamID" if table == "MatchRostersFantasy" else "TeamID"
	var query = ""
	
	if (table == "MatchRostersFantasy"):
		query = "SELECT PlayerID, Name, ShortName, Role as Position, ClassID, RealTeamID, PerformanceVote, DifficultyMultiplier FROM " + table + " 
		WHERE " + col_team + " = ? AND IsStarter = 1 ORDER BY Role DESC"
	else:
		#Per match RPG
		query = "SELECT PlayerID, Name, ShortName, Role as Position, ClassID FROM " + table + " WHERE " + col_team + " = ? AND IsStarter = 1 
		ORDER BY Role DESC"
	return _esegui_query(query, [team_id])
	
func get_match_roster_bench(team_id: int) -> Array:
	var table = _get_current_roster_table()
	var col_team = "FantasyTeamID" if table == "MatchRostersFantasy" else "TeamID"
	var query = ""
	
	if (table == "MatchRostersFantasy"):
		query = " SELECT PlayerID, Name, ShortName, Role as Position, ClassID, RealTeamID, PerformanceVote, DifficultyMultiplier FROM " + table + " 
		WHERE " + col_team + " = ? AND IsStarter = 0 ORDER BY Role DESC"
	else:
		#Per match RPG
		query = "SELECT PlayerID, Name, ShortName, Role as Position, ClassID FROM " + table + " WHERE " + col_team + " = ? AND IsStarter = 0 
		ORDER BY Role DESC"
	return _esegui_query(query, [team_id])

# -----------------------------------------------------------------------------
# 5. LOGICA DI GIOCO (Regole e Modificatori)
# -----------------------------------------------------------------------------

func applica_modificatori_giornata(matchday_data: Array):
	print("--- Applicazione Modificatori da Calendario ---")
	_esegui_query("UPDATE MatchRostersFantasy SET DifficultyMultiplier = 0 WHERE MatchID = 1")
	
	for match in matchday_data:
		var home_diff = match["Home_Diff"]
		var away_diff = match["Away_Diff"]
		
		if home_diff != 0:
			_esegui_query("UPDATE MatchRostersFantasy SET DifficultyMultiplier = ? WHERE RealTeamID = ? AND MatchID = 1", [home_diff, match["Home_ID"]])
		if away_diff != 0:
			_esegui_query("UPDATE MatchRostersFantasy SET DifficultyMultiplier = ? WHERE RealTeamID = ? AND MatchID = 1", [away_diff, match["Away_ID"]])

# Cache Regole
var _perf_rules_cache = {}

func load_all_rules():
	_perf_rules_cache.clear()
	var res_p = _esegui_query("SELECT * FROM ClassPerformanceRules")
	for r in res_p:
		var key = str(r["RoleID"]) # Assicurati che sia stringa se la chiave è stringa
		if not _perf_rules_cache.has(key): _perf_rules_cache[key] = []
		_perf_rules_cache[key].append(r)
	print("✅ Regole caricate.")

# Recupera i colori completi (Primario e Secondario) per Casa o Trasferta
# Restituisce: { "primary": Color, "secondary": Color }
func get_team_colors_full(team_id: int, is_home_kit: bool, kit_path: String) -> Dictionary:
	# 1. Definisci i nomi delle colonne nel DB (Assicurati che coincidano con la tabella Teams!)
	var col_pri = "HomeColorPrimary" if is_home_kit else "AwayColorPrimary"
	var col_sec = "HomeColorSecondary" if is_home_kit else "AwayColorSecondary"
	
	# Default result
	var result = { "primary": Color.GRAY, "secondary": Color.WHITE }
	
	# 2. Interroga il Database
	var query = "SELECT " + col_pri + ", " + col_sec + " FROM FantasyTeams WHERE TeamID = ?"
	var res = _esegui_query(query, [team_id])
	
	if not res.is_empty():
		# --- COLORE PRIMARIO ---
		var hex_p = res[0].get(col_pri, "")
		if hex_p != null and hex_p != "":
			result["primary"] = Color.from_string(hex_p, Color.GRAY)
		else:
			# Fallback: calcola dalla texture se il DB è vuoto
			result["primary"] = get_team_color_from_texture(kit_path)
			
		# --- COLORE SECONDARIO ---
		var hex_s = res[0].get(col_sec, "")
		if hex_s != null and hex_s != "":
			result["secondary"] = Color.from_string(hex_s, Color.WHITE)
		else:
			# Fallback: usa bianco o nero per contrasto se manca il secondario
			result["secondary"] = Color.WHITE 
	else:
		# Fallback totale se la squadra non si trova (es. ID errato)
		result["primary"] = get_team_color_from_texture(kit_path)
			
	return result

# Funzione helper per estrarre il colore medio dalla texture
func get_team_color_from_texture(image_path: String, default_color: Color = Color.GRAY) -> Color:
	if image_path == "" or not ResourceLoader.exists(image_path): 
		return default_color
	
	var texture = load(image_path)
	if not texture: return default_color
	
	var image = texture.get_image()
	# Resize a 1x1 per ottenere la media dei colori
	image.resize(1, 1, Image.INTERPOLATE_CUBIC)
	var c = image.get_pixel(0, 0)
	c.a = 1.0 # Forza opacità completa
	return c
