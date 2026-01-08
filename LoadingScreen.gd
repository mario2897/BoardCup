extends Control

# La scena successiva (la Splash Screen)
const SPLASH_SCENE = preload("res://Scenes/SplashScreen.tscn")
const MIN_LOAD_TIME = 3.0 # Tempo minimo per mostrare la schermata

var start_time = 0.0

func _ready():
	start_time = Time.get_ticks_msec() / 1000.0
	
	# Il DataManager (Autoload) si inizializza qui.
	print("Loading: Avvio connessione DB (Fase 1 completata).")
	
	# Qui potresti aggiungere la logica per attendere che il DB sia pronto
	# (Attualmente non necessario dato che il tuo DataManager è sincrono)

	# Attendi il tempo minimo di caricamento
	await get_tree().create_timer(MIN_LOAD_TIME).timeout
	
	# Passa alla Splash Screen
	get_tree().change_scene_to_packed(SPLASH_SCENE)
