# Nome file: FocusIconButton.gd
extends Button

# 1. Cambiamo le variabili: da Font a Texture2D (immagini)
@export var icona_normale : Texture2D
@export var icona_focus : Texture2D


func _ready():
	# Collega i segnali di FOCUS
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	
	# 2. Aggiungiamo i segnali per il MOUSE (hover)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# 3. Imposta l'icona iniziale
	_on_focus_exited()


# --- Eventi di INGRESSO (Focus o Mouse) ---

func _on_focus_entered():
	# Applica l'icona di focus
	self.icon = icona_focus

func _on_mouse_entered():
	# Applica l'icona di focus
	self.icon = icona_focus


# --- Eventi di USCITA (Focus o Mouse) ---

func _on_focus_exited():
	# Ha perso il focus. Controlliamo se il mouse è ancora sopra.
	# get_local_mouse_position() ci dice dove si trova il mouse
	# get_rect().has_point() controlla se quella posizione è DENTRO il bottone
	
	var mouse_is_over = get_rect().has_point(get_local_mouse_position())
	
	# Ripristina l'icona normale SOLO SE anche il mouse è fuori
	if not mouse_is_over:
		self.icon = icona_normale

func _on_mouse_exited():
	# Il mouse è uscito. Controlliamo se ha ancora il focus.
	
	# Ripristina l'icona normale SOLO SE non ha più il focus
	if not has_focus():
		self.icon = icona_normale
