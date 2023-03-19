extends Node

var minigames = {
	"rock_paper_scissors": preload("res://rps/rock_paper_scissors.tscn"),
	"tictactoe": preload("res://tictactoe/tictactoe.tscn")
}

func start_minigame(minigame_name: String) -> GameOutcome.GameOutcome:
	var game = minigames[minigame_name].instantiate()
	get_tree().root.add_child(game)
	var outcome = await game.game_complete
	get_tree().root.remove_child(game)
	return outcome
