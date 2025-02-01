class_name Simulation
extends Node2D

@export var number_of_particles := 100
@export var number_of_rows := 10
@export var starting_velocity := Vector2.ZERO
@export var particle_radius : float = 5.0
@export var separation : float = 5.0
@export var gravity : float = 200
@export var damping : float = 1.0

@onready var viewport_size : Vector2i = DisplayServer.window_get_size()


var particles : Array[Particle]


var always_on_top = true


func _ready() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, always_on_top)
	Particle.simulation = self
	for i in range(number_of_particles):
		var x = (i % number_of_rows - number_of_rows / 2) * (particle_radius * 2 + separation)
		var y = floor(i / number_of_rows - (number_of_particles / number_of_rows / 2)) * (particle_radius * 2 + separation)
		var pos := Vector2(x, y)
		particles.append(Particle.new(pos, starting_velocity))


func _process(delta: float) -> void:
	for i in range(particles.size()):
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
		
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()
		
	
class Particle:
	var position: Vector2
	var velocity: Vector2
	static var simulation: Simulation
	
	func _init(pos, vel) -> void:
		position = pos
		velocity = vel
	
	func update(delta : float):
		velocity.y += simulation.gravity * delta
		position += velocity * delta
		handle_collision()
		
	func handle_collision():
		if position.y > simulation.viewport_size.y / 2 - simulation.particle_radius:
			velocity.y *= -1 * simulation.damping
			position.y = simulation.viewport_size.y / 2 - simulation.particle_radius
			
		if  position.y < -simulation.viewport_size.y / 2 + simulation.particle_radius:
			velocity.y *= -1 * simulation.damping
			position.y = -simulation.viewport_size.y / 2 + simulation.particle_radius
	
