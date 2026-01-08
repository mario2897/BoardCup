extends Control

@onready var first_button = $VBoxContainer/Friendly

func _ready():
	first_button.grab_focus()
	$VBoxContainer/Continue.disabled = true
	$VBoxContainer/NewCareer.disabled = true
	$VBoxContainer/LoadCareer.disabled = true
	$VBoxContainer/RewriteHistory.disabled = true

func _on_button_Friendly_pressed():
	GlobalVariables.ModalitàPartita = "RPG"
	get_tree().change_scene_to_file("res://Scenes/TeamSelector.tscn")

func _on_button_Back_pressed():
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
	
func _on_button_Continue_pressed():
	get_tree().change_scene_to_file("res://Scenes/.tscn")
	
func _on_button_NewCareer_pressed():
	get_tree().change_scene_to_file("res://Scenes/.tscn")
	
func _on_button_LoadCareer_pressed():
	get_tree().change_scene_to_file("res://Scenes/.tscn")
	
func _on_button_RewriteHistory_pressed():
	get_tree().change_scene_to_file("res://Scenes/.tscn")
