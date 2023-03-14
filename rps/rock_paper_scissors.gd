extends Node2D


var actor_prefab: PackedScene = preload("res://rps/rps_actor.tscn")
var actors: Array[Node2D] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(50):
		var a: Area2D = actor_prefab.instantiate()
		if i == 0:
			a.is_player = true
		self.actors.append(a)
		self.add_child(a)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
