extends Node

var vn_scene: PackedScene = preload("res://visual_novel/visual_novel_scene.tscn")
var active_scene: Node = null

var _story: Dictionary  
var _characters: Dictionary  # character name to list of emotions
var _backgrounds: Dictionary
var ambiance: Dictionary


func get_background(bg_name: String) -> ImageTexture:
	return self._backgrounds[bg_name.to_lower()]


func get_character(character_name: String, emotion: String = "") -> ImageTexture:
	if emotion == "" or emotion == "null":
		emotion = "default"
	return self._characters[character_name.to_lower()][emotion.to_lower()]


func load_story_from_json(json_string: String):
	var all_data = JSON.parse_string(json_string)
	
	self._story = all_data["story"]
	var assets = all_data["assets"]
	var chars = assets["characters"]
	var bgs = assets["backgrounds"]
	var sfx = assets["sounds"]
	var afx = assets["ambiance"]  # Music, etc.
	
	# Convert images.
	self._characters = {}
	for character_name in chars.keys():
		var emotions = chars[character_name]
		self._characters[character_name.to_lower()] = {}
		for emote in emotions.keys():
			var image_data: String = chars[character_name][emote]
			self._characters[character_name.to_lower()][emote.to_lower()] = self.load_image_from_story_asset(image_data)
	
	for background_name in bgs.keys():
		self._backgrounds[background_name.to_lower()] = load_image_from_story_asset(bgs[background_name])
	
	printerr("TODO: Load ambiance")


func load_image_from_story_asset(image_data: String) -> ImageTexture:
	# Base64 -> bytes -> Image -> ImageTexture -> Texture2D
	#var image = Image.load_from_file("res://icon.svg")
	#var texture = ImageTexture.create_from_image(image)
	#$Sprite2D.texture = texture
	var image: Image = Image.new()
	var img_tex: ImageTexture
	if image_data.begins_with("png:"):
		print("Load b64")
		image.load_png_from_buffer(Marshalls.base64_to_raw(image_data.substr(len("png:"))))
		img_tex = ImageTexture.create_from_image(image)
	elif image_data.begins_with("file:"):
		print("Load file ", image_data.substr(len("file:")))
		image = Image.load_from_file("user://" + image_data.substr(len("file:")))
		img_tex = ImageTexture.create_from_image(image)
	else:
		printerr("Failed to load image asset with type: ", image_data.substr(0, 10))
	return img_tex


func save_default_story():
	if FileAccess.file_exists("user://default_story.json"):
		return
	# Creates the default story in the user data folder if it does not exist.
	print("Creating default story.")
	var fout = FileAccess.open("user://default_story.json", FileAccess.WRITE)
	var fin = FileAccess.open("res://default_story.json", FileAccess.READ)
	fout.store_string(fin.get_as_text())


# Called when the node enters the scene tree for the first time.
func _ready():
	self.save_default_story()
	var fin = FileAccess.open("user://default_story.json", FileAccess.READ)
	self.load_story_from_json(fin.get_as_text())


func switch_scene(scene_name: String):
	if is_instance_valid(self.active_scene):
		# We have an old active scene.
		self.active_scene.queue_free()
		self.active_scene = null
	var new_scene = self.vn_scene.instantiate()
	get_tree().root.add_child.call_deferred(new_scene)  # Do this first!
	if not self._story.has(scene_name):
		printerr("Scene name '", scene_name, "' not found in story.")
	new_scene.load_dialog(self._story[scene_name])
	self.active_scene = new_scene
