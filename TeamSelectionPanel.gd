class_name TeamSelectionPanel
extends VBoxContainer

signal team_selected(team_data: Dictionary)
signal back_to_menu_requested 

@export var is_home_team: bool = true

@onready var display_container: HBoxContainer = $SelectedTeam
@onready var display_logo_home: TextureRect = $SelectedTeam/LogoHome
@onready var display_logo_away: TextureRect = $SelectedTeam/LogoAway
@onready var display_name: Label = $SelectedTeam/Name

@onready var league_scroll: ScrollContainer = $LeagueScroll
@onready var league_grid: GridContainer = $LeagueScroll/LeagueGrid
@onready var league_template: Button = $LeagueScroll/LeagueGrid/League
@onready var team_scroll: ScrollContainer = $TeamScroll
@onready var team_grid: GridContainer = $TeamScroll/TeamsGrid
@onready var team_template: Button = $TeamScroll/TeamsGrid/Team

var _selected_team_data = null
var _is_fantasy_mode: bool = false

func _ready():
	league_template.visible = false
	team_template.visible = false
	
	if is_home_team:
		display_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	else:
		display_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	deactivate() 

# --- INPUT INDIETRO ---
func _unhandled_input(event):
	if not visible or process_mode == Node.PROCESS_MODE_DISABLED: return
	
	if event.is_action_pressed("ui_cancel"):
		_handle_back_navigation()

func _handle_back_navigation():
	if team_scroll.visible and not _is_fantasy_mode:
		_show_leagues()
		if league_grid.get_child_count() > 0:
			league_grid.get_child(0).grab_focus()
		get_viewport().set_input_as_handled()
	else:
		emit_signal("back_to_menu_requested")
		get_viewport().set_input_as_handled()


# --- ATTIVAZIONE / DISATTIVAZIONE (TRASPARENZA) ---

func activate():
	# 1. Rendi completamente visibile
	self.modulate.a = 1.0 
	
	# 2. RIATTIVA L'INPUT E IL FOCUS
	self.process_mode = Node.PROCESS_MODE_INHERIT
	
	reset_selection()
	
	if _is_fantasy_mode:
		_show_fantasy_grid()
		_populate_fantasy_grid()
		await get_tree().process_frame
		if team_grid.get_child_count() > 1:
			team_grid.get_child(1).grab_focus()
	else:
		_show_leagues()
		_populate_league_grid()
		await get_tree().process_frame
		if league_grid.get_child_count() > 1:
			league_grid.get_child(1).grab_focus()

func deactivate():
	# 1. Rendi semitrasparente (ma mantieni lo spazio occupato!)
	self.modulate.a = 0.3 
	
	# 2. DISATTIVA COMPLETAMENTE L'INPUT
	# Questo impedisce al mouse e alle frecce di interagire con questo pannello
	self.process_mode = Node.PROCESS_MODE_DISABLED

# --- ALTRE FUNZIONI (Completamento e Reset) ---

func set_fantasy_mode(is_fantasy: bool):
	_is_fantasy_mode = is_fantasy

func show_completed_state(team_data):
	_selected_team_data = team_data
	
	# Mostra come completato, ma disabilitato per l'input
	self.modulate.a = 1.0
	self.process_mode = Node.PROCESS_MODE_DISABLED
	
	league_scroll.visible = false
	team_scroll.visible = false
	
	var name_show = _selected_team_data.get("NameShort", "")
	if name_show == "": name_show = _selected_team_data.get("Name", "Selezionata")
	display_name.text = name_show
	
	var logo_path_db = _selected_team_data.get("LogoPath", "")
	
	if is_home_team:
		if FileAccess.file_exists(logo_path_db):
			display_logo_away.texture = load(logo_path_db)
		display_logo_away.visible = true
		display_logo_home.visible = false
	else:
		if FileAccess.file_exists(logo_path_db):
			display_logo_home.texture = load(logo_path_db)
		display_logo_home.visible = true
		display_logo_away.visible = false
		
	display_name.visible = true

func reset_selection():
	_selected_team_data = null
	display_name.text = "Selected Team"
	display_name.visible = true
	display_logo_home.visible = false 
	display_logo_away.visible = false
	
	if _is_fantasy_mode:
		_show_fantasy_grid()
	else:
		_show_leagues()


# --- POPOLAMENTO ---

func _populate_league_grid():
	for child in league_grid.get_children():
		if child != league_template: 
			child.queue_free()
	var leagues_data: Array = DataManager.get_all_leagues()
	for league_data in leagues_data:
		var btn: Button = league_template.duplicate()
		btn.visible = true
		var logo_display: TextureRect = btn.get_node("Logo")
		var logo_path_db = league_data.get("LogoPath", "")
		if FileAccess.file_exists(logo_path_db):
			logo_display.texture = load(logo_path_db)
		btn.pressed.connect(_on_league_pressed.bind(league_data))
		btn.mouse_entered.connect(_on_mouse_hovered.bind(btn)) 
		btn.mouse_exited.connect(_on_focus_exited)
		btn.focus_entered.connect(_on_focus_entered.bind(league_data)) 
		btn.focus_exited.connect(_on_focus_exited)
		league_grid.add_child(btn)

func _populate_team_grid(league_id: String):
	for child in team_grid.get_children():
		if child != team_template: 
			child.queue_free()
	var teams_data: Array = DataManager.get_teams_by_league(league_id)
	for team_data in teams_data:
		_create_team_button(team_data)

func _populate_fantasy_grid():
	for child in team_grid.get_children():
		if child != team_template: 
			child.queue_free()
	var teams_data: Array = DataManager.get_all_fantasy_teams()
	for team_data in teams_data:
		_create_team_button(team_data)

func _create_team_button(team_data: Dictionary):
	var btn: Button = team_template.duplicate()
	btn.visible = true
	var logo_display: TextureRect = btn.get_node("Logo")
	
	var logo_path_db = team_data.get("LogoPath", "")
	if FileAccess.file_exists(logo_path_db):
		logo_display.texture = load(logo_path_db)
	
	btn.pressed.connect(_on_team_selected.bind(team_data))
	btn.mouse_entered.connect(_on_mouse_hovered.bind(btn))
	btn.mouse_exited.connect(_on_focus_exited)
	btn.focus_entered.connect(_on_focus_entered.bind(team_data))
	btn.focus_exited.connect(_on_focus_exited)
	team_grid.add_child(btn)

# --- EVENTI INTERNI ---

func _on_league_pressed(league_data):
	var league_id = league_data.get("LeagueID", "")
	if league_id == "": return
	_populate_team_grid(league_id)
	_show_teams() 
	
	await get_tree().process_frame
	if team_grid.get_child_count() > 1:
		team_grid.get_child(1).grab_focus()

func _on_team_selected(team_data):
	emit_signal("team_selected", team_data)

# --- FOCUS ---

func _on_mouse_hovered(button: Button):
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		button.grab_focus()

func _on_focus_entered(data):
	var txt = data.get("NameShort", "")
	if txt == "": txt = data.get("Name", "")
	if txt == "": txt = data.get("LeagueName", "...")
	
	display_name.text = txt
	display_logo_home.visible = false
	display_logo_away.visible = false

func _on_focus_exited():
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		pass 
	elif _selected_team_data != null:
		var name_show = _selected_team_data.get("NameShort", "")
		if name_show == "": name_show = _selected_team_data.get("Name", "Selezionata")
		display_name.text = name_show
		
		if is_home_team:
			display_logo_away.visible = true
			display_logo_home.visible = false
		else:
			display_logo_home.visible = true
			display_logo_away.visible = false
	else:
		display_name.text = "Selected Team"
		display_logo_home.visible = false
		display_logo_away.visible = false


# --- VISIBILITÀ ---

func _show_leagues():
	league_scroll.visible = true
	team_scroll.visible = false

func _show_teams():
	league_scroll.visible = false
	team_scroll.visible = true

func _show_fantasy_grid():
	league_scroll.visible = false
	team_scroll.visible = true
