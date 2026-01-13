extends Control

# --- RIFERIMENTI ---
@onready var home_color1 = $RowsTemplate/ScoreboardTemplate/HomeTeam/Background/TeamColors/FirstColorHome
@onready var home_color2 = $RowsTemplate/ScoreboardTemplate/HomeTeam/Background/TeamColors/SecondColorHome
@onready var home_name_lbl = $RowsTemplate/ScoreboardTemplate/HomeTeam/Background/HomeColumn/HomeName
@onready var home_logo_rect = $RowsTemplate/ScoreboardTemplate/HomeTeam/Background/HomeColumn/HomeLogoContainer/HomeLogo

@onready var away_color1 = $RowsTemplate/ScoreboardTemplate/AwayTeam/Background/TeamColors/FirstColorAway
@onready var away_color2 = $RowsTemplate/ScoreboardTemplate/AwayTeam/Background/TeamColors/SecondColorAway
@onready var away_name_lbl = $RowsTemplate/ScoreboardTemplate/AwayTeam/Background/AwayColumn/AwayName
@onready var away_logo_rect = $RowsTemplate/ScoreboardTemplate/AwayTeam/Background/AwayColumn/AwayLogoContainer/AwayLogo

# Nota: Ho corretto il percorso basandomi sulla scena che mi hai mandato
# (ScoreboardTemplate -> Score -> ScoreDivisor)
@onready var home_score_lbl = $RowsTemplate/Points/ScoreDivisor/HomePoints
@onready var away_score_lbl = $RowsTemplate/Points/ScoreDivisor/AwayPoints

func _ready():
	# Inizializza a zero
	update_scores(0, 0)

# Setup completo: Nomi, Loghi e Colori
func setup_match(h_data: Dictionary, a_data: Dictionary):
	# 1. Imposta Nomi
	home_name_lbl.text = str(h_data.get("Abbreviation", h_data.get("Name", "HOME"))).to_upper()
	away_name_lbl.text = str(a_data.get("Abbreviation", a_data.get("Name", "AWAY"))).to_upper()
	
	# 2. Imposta Loghi
	var h_logo = h_data.get("LogoPath", "")
	var a_logo = a_data.get("LogoPath", "")
	
	if h_logo != "" and ResourceLoader.exists(h_logo):
		home_logo_rect.texture = load(h_logo)
	if a_logo != "" and ResourceLoader.exists(a_logo):
		away_logo_rect.texture = load(a_logo)
		
	# 3. Imposta i Colori
	var h_col_prim = _parse_color(h_data.get("PrimaryColor", "FFFFFF"))
	var h_col_sec = _parse_color(h_data.get("SecondaryColor", "000000"))
	
	var a_col_prim = _parse_color(a_data.get("PrimaryColor", "FFFFFF"))
	var a_col_sec = _parse_color(a_data.get("SecondaryColor", "000000"))
	
	# CHIAMATA CORRETTA: Passiamo i due rettangoli + la label
	_apply_team_colors(home_color1, home_color2, h_col_prim, h_col_sec)
	_apply_team_colors(away_color1, away_color2, a_col_prim, a_col_sec)

func update_scores(h_score: float, a_score: float):
	home_score_lbl.text = str(float(h_score))
	away_score_lbl.text = str(float(a_score))

# --- HELPER PER I COLORI (CORRETTO PER COLOR RECT) ---
# Ora accetta ColorRect invece di Panel
func _apply_team_colors(rect1: ColorRect, rect2: ColorRect, col_prim: Color, col_sec: Color):
	# Applica colori direttamente alla proprietà .color dei ColorRect
	if rect1: rect1.color = col_prim
	if rect2: rect2.color = col_sec

# Converte stringa hex o Color in Color
func _parse_color(data) -> Color:
	if data is Color: return data
	if data is String:
		if data.is_valid_html_color():
			return Color(data)
		if !data.begins_with("#") and data.length() == 6:
			return Color("#" + data)
	return Color.WHITE
