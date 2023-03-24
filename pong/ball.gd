extends RigidBody2D

var pending_teleport: bool = false
var pending_teleport_destination: Vector2 = Vector2.ZERO
@export var start_speed: float = 500.0
@export var min_speed: float = 460.0

@onready var collision_noise: AudioStreamPlayer2D = %BounceNoise

func _ready():
	self.randomize_velocity()
	self.body_entered.connect(_bounced)


func reset_to(pos: Vector2):
	self.randomize_velocity()
	self.pending_teleport = true
	self.pending_teleport_destination = pos


func randomize_velocity():
	self.linear_velocity = Vector2(randf(), 0.2*randf()).normalized()*start_speed


func _bounced(body):
	self.collision_noise.play()


func _physics_process(delta):
	if not self.freeze:
		# Measure the difference between our current speed and the target.
		# Basic:
		#self.linear_velocity = self.linear_velocity.normalized() * speed
		# Advanced:
		var lv = self.linear_velocity
		var lv_magnitude = lv.length()
		if lv_magnitude < self.min_speed:
			self.apply_central_impulse(lv.normalized() * (self.min_speed - lv_magnitude))
	

func _integrate_forces(state):
	if self.pending_teleport:
		self.pending_teleport = false
		state.transform.origin = self.pending_teleport_destination
