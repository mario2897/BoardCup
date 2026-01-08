extends Node

# Tipi di input possibili
enum InputScheme { KEYBOARD_GAMEPAD, MOUSE }

var current_input_scheme = InputScheme.MOUSE
var last_focused_control: Control = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	
	# Parti subito in modalità tastiera (Opzionale)
	_switch_to_keyboard_mode()

func _input(event):
	# --- RILEVA TASTIERA / GAMEPAD ---
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		# Se stavamo usando il mouse, passiamo alla tastiera
		if current_input_scheme == InputScheme.MOUSE:
			_switch_to_keyboard_mode()
			
		# Ripristina focus se perso
		if event.is_pressed() and get_viewport().gui_get_focus_owner() == null:
			_restore_focus()

	# --- RILEVA MOUSE ---
	elif event is InputEventMouse:
		# Ignora piccoli movimenti (drift)
		if event is InputEventMouseMotion and event.relative.length() < 2.0:
			return
			
		if current_input_scheme != InputScheme.MOUSE:
			_switch_to_mouse_mode()

# --- LOGICA CAMBIO MODALITÀ ---

func _switch_to_keyboard_mode():
	current_input_scheme = InputScheme.KEYBOARD_GAMEPAD
	
	# 1. Nascondi il cursore
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	# 2. TRUCCO FONDAMENTALE: Sposta il mouse in un angolo sicuro (0,0)
	# In questo modo esce dall'area di qualsiasi bottone, cancellando l'hover.
	get_viewport().warp_mouse(Vector2(0, 0))
	
	# 3. Recupera il focus sull'ultimo elemento usato
	_restore_focus()
	print("Input: Tastiera attivo (Mouse spostato a 0,0)")

func _switch_to_mouse_mode():
	current_input_scheme = InputScheme.MOUSE
	
	# Mostra il cursore
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("Input: Mouse attivo")

# --- GESTIONE INTELLIGENTE DEL FOCUS ---

func _on_focus_changed(control: Control):
	if control != null:
		last_focused_control = control

func _restore_focus():
	if last_focused_control != null and is_instance_valid(last_focused_control) and last_focused_control.is_visible_in_tree():
		last_focused_control.grab_focus()
	else:
		# Se non abbiamo memoria, cerca il primo bottone valido
		var first_valid = _find_first_valid_focus(get_tree().root)
		if first_valid:
			first_valid.grab_focus()

func _find_first_valid_focus(node: Node) -> Control:
	if node is Control and node.focus_mode == Control.FOCUS_ALL and node.is_visible_in_tree():
		return node
	for child in node.get_children():
		var found = _find_first_valid_focus(child)
		if found: return found
	return null
