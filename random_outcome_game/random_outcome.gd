extends Node

signal game_complete(GameOutcome)
var signal_emitted: bool = false

# This 'game' immediately emits a win/lost/draw signal at random.  
# It's a hack for when we want a randomly branched narrative.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not signal_emitted:
		signal_emitted = true
		var out = [GameOutcome.GameOutcome.WIN, GameOutcome.GameOutcome.LOSE, GameOutcome.GameOutcome.DRAW]
		emit_signal(out.pick_random())
