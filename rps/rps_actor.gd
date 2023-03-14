extends Area2D

const PADDING = 50
const SPEED = 300.0

@export var is_player: bool = false
var velocity: Vector2 = Vector2.ZERO

# Get the gravity from the project settings to be synced with RigidBody nodes.
#var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

enum RPSState {
	ROCK = 0,
	PAPER = 1,
	SCISSORS = 2,
}
@export var state = RPSState.ROCK
func get_rps_state():
	return self.state
	

func _ready():
	self.randomize_state()
	self.body_shape_entered.connect(self._on_shape_entered)
	self.body_entered.connect(self._on_shape_entered)
	

func randomize_state():
	self.position.x = randi_range(PADDING, get_viewport_rect().size.x-PADDING)
	self.position.y = randi_range(PADDING, get_viewport_rect().size.y-PADDING)
	self.state = [RPSState.ROCK, RPSState.PAPER, RPSState.SCISSORS][randi()%3]


func _process(delta):
	%RockSprite.visible = false
	%PaperSprite.visible = false
	%ScissorsSprite.visible = false
	match self.state:
		RPSState.ROCK:
			%RockSprite.visible = true
		RPSState.PAPER:
			%PaperSprite.visible = true
		RPSState.SCISSORS:
			%ScissorsSprite.visible = true


func _physics_process(delta):
	# Add the gravity.
	#if not is_on_floor():
	#	velocity.y += gravity * delta

	# Handle Jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
	#	velocity.y = JUMP_VELOCITY
	var dx = 0.0
	var dy = 0.0
	if self.is_player:
		dx = Input.get_axis("move_left", "move_right")
		dy = Input.get_axis("move_up", "move_down")
	if dx or dy:
		velocity.x = dx
		velocity.y = dy
		velocity = velocity.normalized() * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)

	self.position += velocity*delta
	
	# Keep inside the screen.
	var view_rect = get_viewport_rect()
	self.global_position.x = min(max(0, self.global_position.x), view_rect.size.x)
	self.global_position.y = min(max(0, self.global_position.y), view_rect.size.y)


func _on_shape_entered(other):
	if other.has_method("get_rps_state"):
		var other_state = other.get_rps_state()
		if self.state == RPSState.ROCK and other_state == RPSState.PAPER:
			self.state = RPSState.PAPER
		elif self.state == RPSState.PAPER and other_state == RPSState.SCISSORS:
			self.state = RPSState.SCISSORS
		elif self.state == RPSState.SCISSORS and other_state == RPSState.ROCK:
			self.state = RPSState.ROCK
