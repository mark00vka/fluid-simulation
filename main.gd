class_name Simulation
extends Control


const mass = 1


@export_category("")
@export var numberOfParticles : int = 100
@export var numberOfRows : int = 10
@export var startingVelocity := Vector2.ZERO
@export var particleRadius : float = 5.0
@export var s = 15

@export_category("")
@export_range(50, 1000, 10) var smoothingRadius : float = 20.0
@export var separation : float = 5.0
@export var gravity : float = 100
@export var damping : float = 1.0

@export_category("")
@export_range(0.01, 0.07, 0.001) var targetDensity : float = 1.0
@export_range(1, 10, 0.1) var pressureMultiplier : float = 1.0
@export var densityGradient : Gradient

var viewportSize : Vector2i = DisplayServer.window_get_size()


var spatialLookup: SpatialLookup = SpatialLookup.new()
var particles : Array[Particle]
var always_on_top = true


func _ready() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, always_on_top)
	Particle.simulation = self
	spatialLookup.simulation = self
	
	for i in range(numberOfParticles):
		#var x = (i % numberOfRows - numberOfRows / 2) * (particleRadius * 2 + separation)
		#var y = floor(i / numberOfRows - (numberOfParticles / numberOfRows / 2)) * (particleRadius * 2 + separation)
		var x = randi_range(0, viewportSize.x)
		var y = randi_range(0, viewportSize.y)
		var pos := Vector2(x, y)
		particles.append(Particle.new(pos, startingVelocity))
		
	spatialLookup.generateSpatialLookup()


func _process(delta: float) -> void:
	if Engine.get_process_frames() % 100 != 0:
		pass
	
	spatialLookup.generateSpatialLookup()
		
	for i in range(particles.size()):
		particles[i].update_densities()
		
	for i in range(particles.size()):
		particles[i].update_velocity(delta)
		
	for i in range(particles.size()):
		particles[i].update_position(delta)
		
	queue_redraw()


func _draw() -> void:
	for i in range(viewportSize.x / s + 1):
		for j in range(viewportSize.y / s + 1):
			var density = calculate_density(Vector2i(i, j) * s)
			var densityError = inverse_lerp(targetDensity * 0.5, targetDensity * 1.5, density)
			var color = sample_gradient(densityError)
			color.a = 0.3
			draw_circle(Vector2i(i, j) * s, s, color)
			
	var selected_particles = spatialLookup.get_particle_indices(get_global_mouse_position())
	
	for i in range(particles.size()):
		var densityError = inverse_lerp(targetDensity * 0.5, targetDensity * 1.5, particles[i].density)
		if i in selected_particles:
			draw_circle(particles[i].position, particleRadius, Color.REBECCA_PURPLE)
		else:
			draw_circle(particles[i].position, particleRadius, Color.BLACK)
		
		
func sample_gradient(l : float):
	return densityGradient.sample(l)
		

func calculate_density(pos: Vector2):
	var density = 0
	
	for particle in particles:
		var dst = pos.distance_to(particle.position)
		var influence = SmoothingFunction.smoothing_kernel(smoothingRadius, dst)
		density += mass * influence
		
	return density
	
	
func convert_density_to_pressure(density: float):
	var densityDifference = min(0, targetDensity - density)
	var pressure = densityDifference * pressureMultiplier * 10000
	return pressure
	
	
func calculate_property(pos: Vector2):
	var property = 0
	
	for particle in particles:
		var density = particle.density
		var dst = pos.distance_to(particle.position)
		var influence = SmoothingFunction.smoothing_kernel(smoothingRadius, dst)
		property += particle.property * influence / density
		
	return property
	
	
func calculate_shared_pressure(particleA : Particle, particleB : Particle):
	var pressureA = convert_density_to_pressure(particleA.density)
	var pressureB = convert_density_to_pressure(particleB.density)
	
	return (pressureA + pressureB) / 2

	
func calculate_pressure_force(particle: Particle):
	var pressureForce = Vector2.ZERO
	
	for otherParticle in particles:
		var pos = particle.position
		
		if otherParticle.position == pos: continue
		
		var dst = pos.distance_to(otherParticle.position)
		var dir = (otherParticle.position - pos) / dst

		var influence = SmoothingFunction.smoothing_kernel_derivative(smoothingRadius, pos.distance_to(otherParticle.position))
		var sharedPressure = calculate_shared_pressure(particle, otherParticle)
		pressureForce += - sharedPressure * dir * mass * influence / otherParticle.density
		
	return pressureForce
	
	
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
	var property = 1
	var density = 0
	
	
	static var simulation: Simulation
	
	
	func _init(pos, vel) -> void:
		position = pos
		velocity = vel
	
	
	func update_velocity(delta: float):
		velocity += Vector2.DOWN * simulation.gravity * delta
		
		var pressureForce = simulation.calculate_pressure_force(self)
		var pressureAcceleration = pressureForce / density

		velocity += pressureAcceleration * delta
	
	func update_position(delta : float):
		position += velocity * delta
		handle_collision()
		
		
	func update_densities():
		density = simulation.calculate_density(position)
		
		
	func handle_collision():
		if position.y > simulation.viewportSize.y - simulation.particleRadius:
			velocity.y *= -1 * simulation.damping
			position.y = simulation.viewportSize.y - simulation.particleRadius
			
		if  position.y < 0 + simulation.particleRadius:
			velocity.y *= -1 * simulation.damping
			position.y = 0 + simulation.particleRadius
	
		if position.x > simulation.viewportSize.x - simulation.particleRadius:
			velocity.x *= -1 * simulation.damping
			position.x = simulation.viewportSize.x - simulation.particleRadius
			
		if  position.x < 0 + simulation.particleRadius:
			velocity.x *= -1 * simulation.damping
			position.x = 0 + simulation.particleRadius
	
