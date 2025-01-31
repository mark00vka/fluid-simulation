class_name Simulation
extends Node2D

@export var number_of_particles := 100
@export var number_of_rows := 10
@export var starting_velocity := Vector2.ZERO
@export var particle_radius : float = 5.0
@export var separation : float = 5.0
@export var gravity : float = 200
@export var damping : float = 0.5


var particles : Array[Particle]


var always_on_top = true
@onready var viewport_size : Vector2i = DisplayServer.window_get_size()

		
func _ready() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, always_on_top)
	for i in range(number_of_particles):
		var x = (i % number_of_rows) * (particle_radius * 2 + separation)
		var y = floor(i / number_of_rows) *  (particle_radius * 2 + separation)
		var pos := Vector2(x, y)
		particles.append(Particle.new(pos, starting_velocity))


func _process(delta: float) -> void:
	for i in range(number_of_particles):
		particles[i].update(delta)
	queue_redraw()


func _draw() -> void:
	for particle in particles:
		draw_circle(particle.position, particle_radius, Color.WHITE)
		
	
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		always_on_top = !always_on_top
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, always_on_top)
		print("Always on top:", always_on_top)
		
	
class Particle extends Simulation:
	var pos: Vector2
	var velocity: Vector2
	
	func _init(p, vel) -> void:
		self.pos = p
		velocity = vel
	
	func update(delta : float):
		velocity.y += gravity * delta
		position += velocity * delta
		handle_collision()
		
	func handle_collision():
		if position.y > viewport_size.y / 2:
			velocity.y = -velocity.y * damping
			position.y = viewport_size.y / 2
			
		if  position.y < -viewport_size.y / 2:
			velocity.y = -velocity.y * damping
			position.y = -viewport_size.y / 2
	
