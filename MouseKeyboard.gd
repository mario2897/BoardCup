# InputManager.gd
extends Node

var _is_mouse_hidden: bool = false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_is_mouse_hidden = false

func _input(event):
	
	# --- CONTROLLO DI SICUREZZA ---
	# Se l'albero di scena non è pronto o non ha una scena,
	# non fare assolutamente nulla.
	if not is_instance_valid(get_tree()):
		return
		
	var current_scene = get_tree().get_current_scene()
	if not is_instance_valid(current_scene):
		return

	var main_viewport = current_scene.get_viewport()
	if not is_instance_valid(main_viewport):
		return
	# --- FINE CONTROLLO ---
	

	# --- CASO 1: L'utente muove il mouse ---
	if event is InputEventMouseMotion:
		# Se il mouse era nascosto, mostralo
		if _is_mouse_hidden:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_is_mouse_hidden = false
			
			# Rilascia il focus da qualsiasi pulsante
			main_viewport.gui_release_focus()

	# --- CASO 2: L'utente usa la tastiera/controller ---
	elif event.is_action_pressed("ui_up") or \
		 event.is_action_pressed("ui_down") or \
		 event.is_action_pressed("ui_left") or \
		 event.is_action_pressed("ui_right") or \
		 event.is_action_pressed("ui_accept") or \
		 event.is_action_pressed("ui_cancel"):
		
		# Se il mouse era visibile, nascondilo
		if not _is_mouse_hidden:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
			_is_mouse_hidden = true
