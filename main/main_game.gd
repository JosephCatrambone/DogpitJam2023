extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	StoryManager.switch_scene("start")
	#$Timer.start()
	#await $Timer.timeout

