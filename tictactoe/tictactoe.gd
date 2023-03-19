extends Control

signal game_complete(GameOutcome)

@export var mistake_probability: float = 0.01

var game_over = null
var current_player_x: bool = true  # Current player.  true -> x, false -> o.
var board_state: PackedInt32Array = [0, 0, 0, 0, 0, 0, 0, 0, 0]  # Keeps track of the game state.
var board_marks: Array[TextureButton] = []  # References to the texture buttons for display.
@onready var empty_mark: TextureButton = $Mark
@onready var x_mark: TextureRect = $X
@onready var o_mark: TextureRect = $O
@onready var board: GridContainer = $CenterContainer/Board

func _ready():
	for i in range(0, 9):
		var new_mark: TextureButton = empty_mark.duplicate()
		new_mark.visible = true
		new_mark.pressed.connect(func(): self._mark(i))
		board.add_child(new_mark)
		board_marks.append(new_mark)


func _mark(i: int):
	if self.current_player_x:
		self.board_state[i] = 1
		self.board_marks[i].texture_normal = self.x_mark.texture
	else:
		self.board_state[i] = 2
		self.board_marks[i].texture_normal = self.o_mark.texture
	self.board_marks[i].disabled = true
	self.current_player_x = not self.current_player_x
	self._handle_win()  # We could call this in a loop, I guess?  But it's more efficient to do it here.


func _handle_win():
	var winner = self._get_winner(self.board_state)
	if winner == 1:
		#emit_signal("game_complete", GameOutcome.GameOutcome.WIN)
		game_over = GameOutcome.GameOutcome.WIN
		print("x wins")
	elif winner == 2:
		#emit_signal("game_complete", GameOutcome.GameOutcome.LOSE)
		game_over = GameOutcome.GameOutcome.LOSE
		print("o wins")
	else:
		# Check to see if there are spaces left.
		var spaces_left = 0
		for s in self.board_state:
			if s == 0:
				spaces_left += 1
		if spaces_left == 0:
			#emit_signal("game_complete", GameOutcome.GameOutcome.DRAW)
			game_over = GameOutcome.GameOutcome.DRAW
			print("draw")


func _get_winner(state: PackedInt32Array) -> int:
	# Returns 0 if no winner, 1 if x wins, 2 if o wins.
	const lines = [
		# Rows:
		[0, 1, 2],
		[3, 4, 5],
		[6, 7, 8],
		# Cols:
		[0, 3, 6],
		[1, 4, 7],
		[2, 5, 8],
		# Diagonals:
		[0, 4, 8],
		[2, 4, 6],
	]
	for line in lines:
		if state[line[0]] == state[line[1]] and state[line[0]] == state[line[2]]:
			if state[line[0]] != 0:
				# Everything on this line is the same AND it is not empty.
				return state[line[0]]
	return 0


func _pick_best_move(state: PackedInt32Array, mistake_probability: float = 0.0) -> int:
	var possible_moves: Array = []
	for i in range(0, 9):
		if state[i] == 0:
			possible_moves.append(i)
	if randf() > mistake_probability:
		var move_scores = self._score_moves(state, possible_moves, false)
		var best_score = -100000000
		var best_move = 0
		for mv in move_scores.keys():
			var mv_score = -move_scores[mv]["x_wins"]
			if mv_score > best_score:
				best_move = mv
				best_score = mv_score
		return best_move
	else:
		# Chose a random move.
		return possible_moves[randi()%len(possible_moves)]

func _score_moves(state: PackedInt32Array, possible_moves: Array, x_moving: bool) -> Dictionary:
	# Given the board, return the best square for 'o' to use.
	# Return the state which gives us the maximum number of 'o' wins, followed by the state with the max number of draws.
	var move_outcomes = {}
	for i in possible_moves:
		move_outcomes[i] = {"x_wins": 0, "o_wins": 0, "draws": 0}
	
	for idx in range(len(possible_moves)):
		var move_position = possible_moves.pop_front()
		if x_moving:
			state[move_position] = 1
		else:
			state[move_position] = 2

		var winner = _get_winner(state)
		if winner == 2:
			move_outcomes[move_position]["o_wins"] += 1
		elif winner == 1:
			move_outcomes[move_position]["x_wins"] += 1
		elif len(possible_moves) == 0:
			move_outcomes[move_position]["draws"] += 1
		else:
			# Recursively score.
			var next = self._score_moves(state, possible_moves, not x_moving)
			for mp in next.keys():
				if not x_moving and next[mp]["x_wins"] > 0:
					move_outcomes[move_position]["x_wins"] += next[mp]["x_wins"]
				else:
					move_outcomes[move_position]["o_wins"] += next[mp]["o_wins"]
				move_outcomes[move_position]["draws"] += next[mp]["draws"]
				
		state[move_position] = 0
		possible_moves.push_back(move_position)
	
	return move_outcomes


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not self.current_player_x and self.game_over == null:
		# It's the AI's turn
		var best_move = self._pick_best_move(self.board_state, self.mistake_probability)
		self._mark(best_move)
	if self.game_over != null:
		# We have a win condition.
		emit_signal("game_complete", self.game_over)
