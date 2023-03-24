extends Node

var popover: PackedScene = preload("res://text_popup/text_popup.tscn")

var minigames = {
	"rock_paper_scissors": preload("res://rps/rock_paper_scissors.tscn"),
	"tictactoe": preload("res://tictactoe/tictactoe.tscn"),
	"pong": preload("res://pong/pong.tscn")
}

func start_minigame(minigame_name: String) -> GameOutcome.GameOutcome:
	var game = minigames[minigame_name].instantiate()
	get_tree().root.add_child(game)
	var outcome = await game.game_complete
	self.trigger_popup(outcome)
	get_tree().root.remove_child(game)
	return outcome

func trigger_popup(outcome: GameOutcome.GameOutcome):
	var popover_instance = self.popover.instantiate()
	match outcome:
		GameOutcome.GameOutcome.WIN:
			popover_instance.text = "YOU WIN"
		GameOutcome.GameOutcome.LOSE:
			popover_instance.text = "YOU LOSE"
		GameOutcome.GameOutcome.DRAW:
			popover_instance.text = "DRAW"
	get_tree().root.add_child(popover_instance)
	await popover_instance.complete
