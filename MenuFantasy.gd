extends Control

@onready var first_button = $VBoxContainer/Friendly

func _ready():
	first_button.grab_focus()
	$VBoxContainer/Continue.disabled = true
	$VBoxContainer/NewLeague.disabled = true
	$VBoxContainer/LoadLeague.disabled = true
	$VBoxContainer/Import.disabled = true

func _on_button_Friendly_pressed():
	GlobalVariables.ModalitàPartita = "Fantasy"
	get_tree().change_scene_to_file("res://Scenes/TeamSelector.tscn")

func _on_button_Back_pressed():
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
	
func _on_button_Continue_pressed():
	get_tree().change_scene_to_file("res://Scenes/.tscn")
	
func _on_button_NewLeague_pressed():
	get_tree().change_scene_to_file("res://Scenes/.tscn")
	
func _on_button_LoadLeague_pressed():
	get_tree().change_scene_to_file("res://Scenes/.tscn")
	
func _on_button_Import_pressed():
	get_tree().change_scene_to_file("res://Scenes/.tscn")
