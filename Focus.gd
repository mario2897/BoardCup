# FocusFontButton.gd
extends Button

# Imposta la dimensione desiderata dall'Inspector
@export var focus_font_size: int = 30

func _ready():
	# Collega i segnali del pulsante a questo script
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	
	_on_focus_exited()


func _on_focus_entered():
	add_theme_font_size_override("font_size", focus_font_size)

func _on_focus_exited():
	remove_theme_font_size_override("font_size")
