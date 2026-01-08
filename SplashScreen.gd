extends Control

func _ready():
	# Assicurati che il gioco sia in grado di leggere l'input
	set_process_input(true) 

func _input(event):
	# Rileva la pressione del tasto INVIO ('ui_accept') o SPAZIO ('ui_select')
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"): 
		vai_a_menu()
		
func vai_a_menu():
	# Impedisce l'input multiplo
	set_process_input(false) 
	print("Splash Screen superata. Passaggio a MainMenu.")
	# Passa al Menu Principale (MainMenu.tscn)
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
