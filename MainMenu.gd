extends Control

@onready var first_button = $Background/VBoxContainer/GDRMode

@onready var label_descrizione: Label = $Background/Descrizione

const DESC_GDR = "Modalità GDR: Gioca partite 1v1 usando un sistema di dadi e abilità."
const DESC_FANTASY = "Modalità Fantasy: Simula un'intera giornata di campionato e gestisci la tua squadra."
const DESC_EDITOR = "Editor: Crea e modifica le tue squadre personalizzate."
const DESC_OPTIONS = "Opzioni: Regola le impostazioni audio, video e di gioco."
const QUIT_OPTIONS = "Chiudi il gioco e torna al desktop."

func _ready():
	first_button.grab_focus()
	_on_button_GDRMode_focus_entered()
	$Background/VBoxContainer/Editor.disabled = true
	$Background/VBoxContainer/Options.disabled = true

func _on_button_GDRMode_focus_entered():
	label_descrizione.text = DESC_GDR

func _on_button_FantasyMode_focus_entered():
	label_descrizione.text = DESC_FANTASY

func _on_button_Editor_focus_entered():
	label_descrizione.text = DESC_EDITOR

func _on_button_Options_focus_entered():
	label_descrizione.text = DESC_OPTIONS

func _on_button_Quit_focus_entered():
	label_descrizione.text = QUIT_OPTIONS

func _on_button_GDRMode_pressed():
	get_tree().change_scene_to_file("res://Scenes/MenuGDR.tscn")

func _on_button_FantasyMode_pressed():
	get_tree().change_scene_to_file("res://Scenes/MenuFantasy.tscn")

func _on_button_Editor_pressed():
	get_tree().change_scene_to_file("res://Scenes/Editor.tscn")

func _on_button_Options_pressed():
	get_tree().change_scene_to_file("res://Scenes/Options.tscn")

func _on_button_Quit_pressed():
	get_tree().quit()
