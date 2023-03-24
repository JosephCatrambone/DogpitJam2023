extends Control

signal complete

@export var text: String = ""  # Can set this through instancing the scene, too. 
@export var tween_time: float = 1.0
@export var end_font_size: float = -1.0
@export var final_color: Color = Color(1.0, 1.0, 1.0, 1.0)

@onready var label: Label = $CenterContainer/Label

# Called when the node enters the scene tree for the first time.
func _ready():
	if not text.is_empty():
		label.text = self.text
	
	var tween: Tween = get_tree().create_tween()
	if self.end_font_size > 0.0:
		tween.tween_property(label, "theme_override_font_sizes/font_size", self.end_font_size, self.tween_time)
	tween.tween_property(label, "self_modulate", self.final_color, self.tween_time)
	#tween.interpolate_value("theme_overrides/font_size", )
	await tween.finished
	emit_signal("complete")
	self.queue_free()

