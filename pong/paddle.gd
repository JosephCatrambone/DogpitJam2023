extends AnimatableBody2D

@export var follow_ball: Node2D = null
@export var max_speed: float = 200.0
@export var miss_probability: float = 0.01

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _physics_process(delta):
	if self.follow_ball != null and is_instance_valid(self.follow_ball):
		#self.global_position.y = move_toward(self.position.y, self.follow_ball.global_position.y, randf_range(1.0 - miss_probability, 1.0))
		var delta_y = self.follow_ball.global_position.y - self.global_position.y
		self.position.y += delta_y * (1.0 - randf_range(miss_probability, 1.0))
	else:
		var mouse_pos: Vector2 = get_global_mouse_position()
		var screen_rect: Rect2 = get_viewport_rect()
		if screen_rect.has_point(mouse_pos):
			self.global_position.y = mouse_pos.y


func _notification(what):
	if what == NOTIFICATION_WM_MOUSE_ENTER:
		print("enter")
	elif what == NOTIFICATION_WM_MOUSE_EXIT:
		print("exit")
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		print("focus in")
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		print("focus out")
