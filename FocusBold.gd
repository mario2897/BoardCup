# Nome file: FocusBoldButton.gd
extends Button

@export var font_normale : Font
@export var font_grassetto : Font


func _ready():
	# Collega i segnali "focus_entered" e "focus_exited"
	# del pulsante alle funzioni di questo script.
	# Questo si auto-collega, non devi farlo dall'editor.
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	
	# Assicura che il pulsante inizi con il font normale
	_on_focus_exited()


# Chiamato automaticamente quando il pulsante OTTIENE il focus
func _on_focus_entered():
	# Sovrascrive il tema solo per questo pulsante,
	# applicando il font grassetto.
	add_theme_font_override("font", font_grassetto)


# Chiamato automaticamente quando il pulsante PERDE il focus
func _on_focus_exited():
	# Rimuove la sovrascrittura, tornando al font normale.
	add_theme_font_override("font", font_normale)
