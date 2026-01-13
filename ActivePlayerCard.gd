class_name ActivePlayerCard
extends Control

# --- RIFERIMENTI AI NODI (Aggiornati alla tua scena reale) ---
@onready var background_panel = $BackgroundPanel
@onready var kit_texture = $BackgroundPanel/CardLayout/TeamKit

# Invece di una Label semplice, hai un'istanza di PlayerButtonList
@onready var player_info_display = $BackgroundPanel/CardLayout/DataLayout/NameRatingTag/PlayerMatchNametag 

# I label sono direttamente qui, non c'è un nodo "Value" figlio
@onready var vote_label = $BackgroundPanel/CardLayout/DataLayout/PlayerStats/VotesLayout/Vote
@onready var bonus_label = $BackgroundPanel/CardLayout/DataLayout/PlayerStats/VotesLayout/Bonus_Malus

func _ready():
	reset_card()

func reset_card():
	modulate.a = 0.5 # Sbiadisce carta inattiva
	
	# Reset Testi
	if vote_label: vote_label.text = "Prestazione\n-"
	if bonus_label: bonus_label.text = "Difficoltà\n-"
	
	# Reset del componente nome (se ha un metodo di reset, altrimenti lo nascondiamo o puliamo)
	if player_info_display and player_info_display.has_method("setup"):
		# Passiamo un dizionario vuoto o finto per pulirlo, oppure gestisci il reset internamente
		# Per ora lasciamo così, verrà sovrascritto al setup
		pass

func setup(player_data: Dictionary, kit_path: String, team_colors: Dictionary = {}):
	modulate.a = 1.0 # Opaco (Attivo)
	
	# 1. IMPOSTA KIT
	if kit_path != "" and ResourceLoader.exists(kit_path):
		kit_texture.texture = load(kit_path)
	
	# 2. IMPOSTA NOME (Usando il componente PlayerButtonList)
	if player_info_display:
		if player_info_display.has_method("setup"):
			# Usiamo il metodo setup del tuo prefab per mostrari i dati (Nome, Ruolo, ecc.)
			player_info_display.setup(player_data, team_colors)
			# Disabilitiamo l'interazione se serve solo per visualizzazione
			if player_info_display is BaseButton:
				player_info_display.disabled = true
				player_info_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 3. IMPOSTA VOTO E BONUS
	var voto = float(player_data.get("PerformanceVote", 6.0))
	var bonus = float(player_data.get("DifficultyMultiplier", 0.0))
	
	if vote_label:
		# Formatta il testo mantenendo la scritta "Prestazione" e andando a capo
		vote_label.text = "Prestazione\n%.1f" % voto
		vote_label.modulate = team_colors.get("secondary", Color.BLACK)
		vote_label.add_theme_color_override("font_color", team_colors.get("primary"))
		
	if bonus_label:
		var sign_str = "+" if bonus > 0 else ""
		bonus_label.text = "Difficoltà\n%s%.1f" % [sign_str, bonus]
		
		# Colora il testo
		if bonus > 0: bonus_label.modulate = Color.GREEN
		elif bonus < 0: bonus_label.modulate = Color.RED
		else: 
			bonus_label.modulate = team_colors.get("secondary", Color.BLACK)

	# 4. COLORA IL BORDO (Usa i colori del DB passati dal TurnManager)
	if not team_colors.is_empty():
		var primary = team_colors.get("primary", Color.GRAY)
		var secondary = team_colors.get("secondary", Color.BLACK)
		
		var style = background_panel.get_theme_stylebox("panel")
		if style:
			# Duplica lo stile per non cambiare tutte le carte insieme
			style = style.duplicate()
			style.bg_color = primary
			style.border_color = secondary # O secondary, a tua scelta
			background_panel.add_theme_stylebox_override("panel", style)

# Helper per mostrare la maglia anche quando inattivo
func set_kit_texture(path: String):
	if path != "" and ResourceLoader.exists(path):
		kit_texture.texture = load(path)
