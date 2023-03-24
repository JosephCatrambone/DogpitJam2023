extends Node2D

signal game_complete(GameOutcome)

# It's a little hacky to keep the score as text, but...
@export var score_limit: int = 3
@onready var left_goal: Area2D = %LeftGoal
@onready var right_goal: Area2D = %RightGoal
@onready var left_score: Label = %LeftScore
@onready var right_score: Label = %RightScore
@onready var left_goal_noise: AudioStreamPlayer2D = %LeftGoalNoise
@onready var right_goal_noise: AudioStreamPlayer2D = %RightGoalNoise
@onready var ball: RigidBody2D = %Ball
@onready var ball_start: Marker2D = %BallStartPosition

@export var max_oob_distance: float = 400000000  # How far can the ball go before it's OOB?
@export var time_before_tilt: float = 2.0
var reset_timer: float = 2.0
var dx_threshold: float = 15.0


# Called when the node enters the scene tree for the first time.
func _ready():
	self.left_goal.body_entered.connect(_left_goal_entered)
	self.right_goal.body_entered.connect(_right_goal_entered)


func _left_goal_entered(body):
	if body == ball:
		self.left_goal_noise.play()
		var score = int(self.right_score.text)
		score += 1
		self.right_score.text = str(score)
		self._restart_ball.call_deferred()
		self._check_game_over.call_deferred()


func _right_goal_entered(body):
	if body == ball:
		self.right_goal_noise.play()
		var score = int(self.left_score.text)
		score += 1
		self.left_score.text = str(score)
		self._restart_ball.call_deferred()
		self._check_game_over.call_deferred()
	

func _restart_ball():
	ball.freeze = true
	var vp = get_viewport_rect()
	ball.reset_to(ball_start.global_position)
	ball.freeze = false


func _check_game_over():
	var left_score = int(self.left_score.text)
	var right_score = int(self.right_score.text)
	if left_score >= self.score_limit:
		self.emit_signal("game_complete", GameOutcome.GameOutcome.LOSE)
	elif right_score >= self.score_limit:
		self.emit_signal("game_complete", GameOutcome.GameOutcome.WIN)
	else:
		pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Prevent ball from getting stuck bouncing in the center.
	if abs(self.ball.linear_velocity.x) < self.dx_threshold:
		self.reset_timer -= delta
	if self.reset_timer <= 0.0:
		self.reset_timer = self.time_before_tilt
		self._restart_ball()
		
	if self.ball.global_position.length_squared() > self.max_oob_distance:
		self._restart_ball()
	else:
		print(self.ball.global_position.length_squared())
