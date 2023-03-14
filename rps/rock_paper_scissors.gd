extends Node2D

@export var num_actors: int = 50
var actor_prefab: PackedScene = preload("res://rps/rps_actor.tscn")
var actors: Array[Node2D] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(self.num_actors):
		var a: Area2D = actor_prefab.instantiate()
		if i == 0:
			# Make the player sprite slightly bigger and lighter for visibility.
			a.is_player = true
		self.actors.append(a)
		self.add_child(a)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.check_winner()

func check_winner():
	var actor_counts = {
		RPSActorType.ROCK: 0,
		RPSActorType.PAPER: 0,
		RPSActorType.SCISSORS: 0,
	}
	for a in self.actors:
		var t = a.get_rps_state()
		actor_counts[t] += 1
	for at in actor_counts.keys():
		if actor_counts[at] == num_actors:
			print("Winner: ", at)
			get_tree().reload_current_scene()
