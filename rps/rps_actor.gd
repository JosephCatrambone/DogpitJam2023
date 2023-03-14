extends Area2D

const PADDING = 50
const SPEED = 300.0
const TICKS_BETWEEN_AI_CHECKS = 15

@export var ai_aggression: float = 1.0  # How much the AI will seek prey.
@export var ai_fear: float = 1.0  # How much the AI will avoid predators.
@export var ai_flock: float = 0.01  # How much will the AI move towards the like.
@export var ai_spread: float = 0.1  # How much will the AI move away from the like.
@export var ai_stay_centered: float = 0.007  # How much will the AI move towards the center?
@export var ai_chaos: float = 0.01  # How much will the AI move randomly?
var ticks_to_next_ai_run: int = 0

@export var volition_vector: Vector2 = Vector2.ZERO  # This is set by the player if 'is_player'.
@export var is_player: bool = false
var velocity: Vector2 = Vector2.ZERO

# Get the gravity from the project settings to be synced with RigidBody nodes.
#var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var state = RPSActorType.ROCK
func get_rps_state():
	return self.state
	

func _ready():
	self.randomize_state()
	self.area_shape_entered.connect(self._on_shape_entered)
	self.body_shape_entered.connect(self._on_shape_entered)
	self.body_entered.connect(self._on_shape_entered)
	self.ticks_to_next_ai_run = randi()%TICKS_BETWEEN_AI_CHECKS
	

func randomize_state():
	self.position.x = randi_range(PADDING, get_viewport_rect().size.x-PADDING)
	self.position.y = randi_range(PADDING, get_viewport_rect().size.y-PADDING)
	self.state = [RPSActorType.ROCK, RPSActorType.PAPER, RPSActorType.SCISSORS][randi()%3]


func get_predator_type():
	match self.state:
		RPSActorType.ROCK:
			return RPSActorType.PAPER
		RPSActorType.PAPER:
			return RPSActorType.SCISSORS
		RPSActorType.SCISSORS:
			return RPSActorType.ROCK


func get_prey_type():
	match self.state:
		RPSActorType.ROCK:
			return RPSActorType.SCISSORS
		RPSActorType.PAPER:
			return RPSActorType.ROCK
		RPSActorType.SCISSORS:
			return RPSActorType.PAPER


func _process(delta):
	# Update visuals
	%RockSprite.visible = false
	%PaperSprite.visible = false
	%ScissorsSprite.visible = false
	match self.state:
		RPSActorType.ROCK:
			%RockSprite.visible = true
		RPSActorType.PAPER:
			%PaperSprite.visible = true
		RPSActorType.SCISSORS:
			%ScissorsSprite.visible = true
	%Highlight.visible = self.is_player
	# Update AI
	self.ticks_to_next_ai_run -= 1
	if self.ticks_to_next_ai_run <= 0:
		self.ticks_to_next_ai_run = TICKS_BETWEEN_AI_CHECKS
		self.run_ai()


func run_ai():
	self.volition_vector = Vector2.ZERO
	# TODO: This is kinda' hacky.  We have to get the parent to get the children.
	var move_toward_type = self.get_prey_type()
	var move_away_from_type = self.get_predator_type()
	for c in self.get_parent().get_children():
		if c == self:
			continue
		if c.has_method("get_rps_state"):
			var delta_position: Vector2 = c.global_position - self.global_position
			var delta_length: float = delta_position.length()
			if delta_length < 1e-4:
				continue  # Screwed
			var other_state = c.get_rps_state()
			if other_state == move_toward_type:
				self.volition_vector += delta_position.normalized()*self.ai_aggression / sqrt(delta_length)
			elif other_state == move_away_from_type:
				self.volition_vector -= delta_position.normalized()*self.ai_fear / sqrt(delta_length)
			else:
				self.volition_vector -= delta_position.normalized()*self.ai_spread / sqrt(delta_length)
				self.volition_vector += delta_position.normalized()*self.ai_flock / sqrt(delta_length)
	# Also try and keep things away from the edges.  Mild force towards the middle.
	var delta_center: Vector2 = (get_viewport_rect().size*0.5) - self.global_position
	self.volition_vector += delta_center*self.ai_stay_centered
	
	# Add some noise.
	self.volition_vector += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))*ai_chaos
	
	if self.volition_vector:
		self.volition_vector = self.volition_vector.normalized()


func _physics_process(delta):
	# Add the gravity.
	#if not is_on_floor():
	#	velocity.y += gravity * delta

	# Handle Jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
	#	velocity.y = JUMP_VELOCITY
	if self.is_player:
		self.volition_vector = Vector2.ZERO
		self.volition_vector.x = Input.get_axis("move_left", "move_right")
		self.volition_vector.y = Input.get_axis("move_up", "move_down")
	if self.volition_vector:
		velocity = self.volition_vector.normalized() * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)

	self.position += velocity*delta
	
	# Keep inside the screen.
	var view_rect = get_viewport_rect()
	self.global_position.x = min(max(0, self.global_position.x), view_rect.size.x)
	self.global_position.y = min(max(0, self.global_position.y), view_rect.size.y)


func _on_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int):
	if area.has_method("get_rps_state"):
		var other_state = area.get_rps_state()
		if self.state == RPSActorType.ROCK and other_state == RPSActorType.PAPER:
			self.state = RPSActorType.PAPER
		elif self.state == RPSActorType.PAPER and other_state == RPSActorType.SCISSORS:
			self.state = RPSActorType.SCISSORS
		elif self.state == RPSActorType.SCISSORS and other_state == RPSActorType.ROCK:
			self.state = RPSActorType.ROCK
