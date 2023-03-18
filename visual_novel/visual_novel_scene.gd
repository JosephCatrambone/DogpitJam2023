extends Control

@export var non_speaking_color: Color = Color(0.8, 0.8, 0.8, 0.8)
@export var period_pause_time_scale: float = 10  # When we hit a period, we wait for time_between_characters * this.

@onready var time_between_characters: float = 0.01
var time_to_next_character: float = 0.0
var text_advancement_paused_on_input: bool = false

var _loaded: bool = false
var _raw_data: Dictionary
var actor_name_to_texture_rect: Dictionary = {}
var character_index_to_actor_switch: Dictionary = {}  # Maps an integer to an actor or actor:emote combo.

# These will all be reinitialized in their respective _load_x functions because .load(...) might be called before ready.
@onready var bg: TextureRect = %Background
@onready var dialog_out: RichTextLabel = %DialogOutput
@onready var speaker_images: HBoxContainer = %Speakers
@onready var choices: VBoxContainer = %Choices
@onready var prompt: RichTextLabel = %Prompt

@onready var speaker_template: TextureRect = %SpeakerTemplate
@onready var button_template: Button = %ButtonTemplate


func _ready():
	self.speaker_images.remove_child(self.speaker_template)
	self.choices.remove_child(self.button_template)


func _process(delta):
	self._maybe_advance_dialog(delta)


func load_dialog(data: Dictionary):
	# See the reference scene.
	# Named load_dialog instead of load to avoid name conflict.
	for required_field in ["background", "actors", "text", "prompt", "options", "next", "on_enter", "minigame", "minigame_outcome"]:
		if not data.has(required_field):
			printerr("Scene missing required field: ", required_field)
	self._raw_data = data
	self._finish_loading.call_deferred()


func _finish_loading():
	self._load_bg(self._raw_data)
	self._load_actors(self._raw_data)
	self._load_choices(self._raw_data)
	self._load_text(self._raw_data)
	self._loaded = true


func _load_bg(data: Dictionary):
	# Set the background
	var bg_name = data["background"]
	if bg_name:
		bg.texture = StoryManager.get_background(bg_name)
		bg.visible = true
	else:
		bg.visible = false


func _load_actors(data: Dictionary):
	# Load actors into places.
	var actors = []
	self.actor_name_to_texture_rect.clear()
	for c in self.speaker_images.get_children():
		self.speaker_images.remove_child(c)
		c.queue_free()
	for a_name in data["actors"]:
		var r: TextureRect = self.speaker_template.duplicate()
		self.actor_name_to_texture_rect[a_name.to_lower()] = r
		r.texture = StoryManager.get_character(a_name)
		self.speaker_images.add_child(r)


func _load_choices(data: Dictionary):
	# Preload prompt+option text.
	self.prompt.text = data["prompt"]
	for old_choice in self.choices.get_children():
		self.choices.remove_child(old_choice)
		old_choice.queue_free()
	for prompt_name in data["options"].keys():
		var choice: Button = button_template.duplicate()
		choice.text = prompt_name
		choice.pressed.connect(func(): self._on_choice_pressed(data["options"][choice]))


func _load_text(data: Dictionary):
	# Parse the text and extract characters swaps and key events.
	self.character_index_to_actor_switch.clear()
	# This is a stupid/gross finite-state machine for parsing.
	#var previous_character: String = ''  # Don't bother with escape characters yet.
	var text_buffer: String = ""
	var name_buffer: String = ""
	for c in data["text"]:
		if not name_buffer.is_empty():
			# We are filling the name buffer.
			if c == ']':
				# We finished filling the name buffer.
				self.character_index_to_actor_switch[len(text_buffer)] = name_buffer.strip_edges()  # Have to trim the ' ' prefix.
				name_buffer = ""
			else:
				name_buffer += c
		elif c == '[':  # We were parsing text and came across a left paren.
			name_buffer += " "
		else:
			text_buffer += c
	self.dialog_out.visible_characters = 0
	self.dialog_out.text = text_buffer
	self.set_speaker("")
	#var tr: TextureRect = $MarginContainer/VBoxContainer/Speakers/Speaker1
	#tr.texture = Texture2D.new()
	#tr.texture.get_image().load_png_from_buffer()


func _on_choice_pressed(new_scene):
	StoryManager.switch_scene(new_scene)



func _maybe_advance_dialog(delta):
	if self.text_advancement_paused_on_input:
		if Input.is_anything_pressed() or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			self.text_advancement_paused_on_input = false
		else:
			return
	
	self.time_to_next_character -= delta
	
	# Advance the caret, unless we're going past the end.
	if self.time_to_next_character <= 0.0 and self.dialog_out.visible_characters < len(self.dialog_out.text):
		# Advance the caret:
		self.time_to_next_character = self.time_between_characters
		var last_char_output = self.dialog_out.text[self.dialog_out.visible_characters]
		self.dialog_out.visible_characters += 1
		
		# Check if we need to pause.
		if last_char_output == '.':
			self.time_to_next_character *= self.period_pause_time_scale
		if last_char_output == "\n" or self.character_index_to_actor_switch.has(self.dialog_out.visible_characters + 1):
			self.text_advancement_paused_on_input = true
		
		# We are changing speakers:
		# TODO: This triggers at the same time as the delay.
		if self.character_index_to_actor_switch.has(self.dialog_out.visible_characters):
			var new_visible_character: String = self.character_index_to_actor_switch[self.dialog_out.visible_characters]
			var new_speaker: String = ""
			var new_emotion: String = ""
			if ":" in new_visible_character:
				var arr = new_visible_character.split(":")
				new_speaker = arr[0]
				new_emotion = arr[1]
			else:
				new_speaker = new_visible_character
			self.set_speaker(new_speaker, new_emotion)
		# Finishing the dialog:
		if self.dialog_out.visible_ratio >= 1.0:
			# Done!
			print("Done!")


func set_speaker(name: String, emotion: String = ""):
	# First, darken all non-speakers.
	for c in self.speaker_images.get_children():
		c.self_modulate = self.non_speaking_color
	if name != "" and self.actor_name_to_texture_rect.has(name):
		self.actor_name_to_texture_rect[name].self_modulate = Color.WHITE
		# TODO: It feels wasteful to always be re-setting the emotion.
		self.actor_name_to_texture_rect[name].texture = StoryManager.get_character(name, emotion)
