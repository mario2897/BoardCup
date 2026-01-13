class_name ActivePlayerCardV2
extends Control

# --- RIFERIMENTI ---
@onready var background_panel = $BackgroundPanel
@onready var kit_texture = $BackgroundPanel/CardLayout/TeamKit
# Questo è il tuo componente Nametag personalizzato
@onready var player_nametag = $BackgroundPanel/CardLayout/DataLayout/NameRatingTag/PlayerMatchNametag

# Pannello Info
@onready var stats_panel = $BackgroundPanel/CardLayout/DataLayout/PlayerStats
@onready var vs_label = $BackgroundPanel/CardLayout/DataLayout/PlayerStats/VotesLayout/VS
@onready var opponent_logo = $BackgroundPanel/CardLayout/DataLayout/PlayerStats/VotesLayout/OpponentLogo

# CORREZIONE QUI: Il nome del nodo nella scena è "Difficulty", non "Bonus_Malus"
@onready var modifier_label = $BackgroundPanel/CardLayout/DataLayout/PlayerStats/VotesLayout/Difficulty 

# SETUP: Eseguito all'inizio
func setup(player_data: Dictionary, kit_path: String, team_colors: Dictionary = {}):
	# 1. Kit e Colori
	if kit_path != "" and ResourceLoader.exists(kit_path):
		kit_texture.texture = load(kit_path)
	
	var col_prim = team_colors.get("primary", Color.WHITE)
	var col_sec = team_colors.get("secondary", Color.BLACK)
	_apply_colors(col_prim, col_sec)

	# 2. Setup Nametag (Nome Giocatore)
	if player_nametag:
		player_nametag.setup(player_data, team_colors)

	# 3. Avversario (VS)
	var opp_path = player_data.get("RealOpponentLogoPath", "")
	var opp_name = player_data.get("RealOpponentName", "RIPOSO")
	
	if opp_path != "" and ResourceLoader.exists(opp_path):
		opponent_logo.texture = load(opp_path)
		opponent_logo.visible = true
		vs_label.visible = true
		vs_label.text = "VS"
	else:
		opponent_logo.texture = null
		opponent_logo.visible = false
		vs_label.visible = true
		vs_label.text = opp_name

	# 4. MOSTRA SUBITO IL MODIFICATORE
	# Ora il nodo "modifier_label" punta correttamente a "Difficulty"
	var diff = float(player_data.get("DifficultyMultiplier", 0.0))
	if modifier_label:
		# Formatta stringa: es. "Difficoltà: +0.5" o "Difficoltà: -1.0"
		var sign = "+" if diff > 0 else ""
		modifier_label.text = "Difficoltà: %s%.1f" % [sign, diff]
		
# STEP 1: RIVELA VOTO (Mandalo al Nametag)
func reveal_base_vote(vote: float):
	# Invece di scriverlo qui, lo passiamo al Nametag
	if player_nametag and player_nametag.has_method("show_vote_result"):
		player_nametag.show_vote_result(vote)

# STEP 2: TOTALE (Vuoto per ora, come richiesto)
func reveal_final_outcome(_bonus: float, _total: float, _text: String = ""):
	pass

# --- UTILITY COLORI ---
func _apply_colors(primary: Color, secondary: Color):
	_style_panel(background_panel, secondary)
	_style_panel(stats_panel, primary)
	_style_label(modifier_label, secondary)
	_style_label(vs_label, secondary)

func _style_panel(panel: Control, bg_color: Color):
	if not panel: return
	
	# Recupera lo stile attuale
	var style = panel.get_theme_stylebox("panel")
	
	# Se esiste, duplicalo e cambialo
	if style:
		var new_style = style.duplicate()
		if new_style is StyleBoxFlat:
			new_style.bg_color = bg_color
			# new_style.border_color = bg_color # Opzionale
		panel.add_theme_stylebox_override("panel", new_style)

func _style_label(label: Label, text_color: Color):
	if not label: return
	label.add_theme_color_override("font_color", text_color)
	var style = label.get_theme_stylebox("normal")
	if style and style is StyleBoxFlat:
		var new_style = style.duplicate()
		new_style.bg_color = Color.TRANSPARENT
		label.add_theme_stylebox_override("normal", new_style)
