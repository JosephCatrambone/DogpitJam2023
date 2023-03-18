extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	#$Timer.start()
	#await $Timer.timeout


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_released("ui_accept"):
		StoryManager.switch_scene("start")
