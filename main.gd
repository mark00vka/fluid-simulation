class_name Simulation
extends Control


const mass = 1


@export_category("")
@export var numberOfParticles : int = 100
@export var numberOfRows : int = 10
@export var startingVelocity := Vector2.ZERO
@export var particleRadius : float = 5.0
@export var s = 30

@export_category("")
@export_range(50, 1000, 10) var smoothingRadius : float = 20.0
@export var separation : float = 5.0
@export var gravity : float = 100
@export var damping : float = 1.0

@export_category("")
@export_range(0.01, 0.07, 0.001) var targetDensity:float = 0.1
	
@export_range(1, 100, 0.1) var pressureMultiplier : float = 1.0
@export var densityGradient : Gradient
@export var speedGradient : Gradient

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
	
	for i in range(particles.size()):
		particles[i].update_predicted_position(delta)
	
	spatialLookup.generateSpatialLookup()
	
	for i in range(particles.size()):
		particles[i].update_densities()
		
	for i in range(particles.size()):
		particles[i].update_velocity(delta)
		
	for i in range(particles.size()):
		particles[i].update_position(delta)
		
	queue_redraw()


func _draw() -> void:
	if s > 0:
		for i in range(viewportSize.x / s + 1):
			for j in range(viewportSize.y / s + 1):
				var density = calculate_density(Vector2i(i, j) * s)
				var densityError = inverse_lerp(targetDensity * 0.5, targetDensity * 1.5, density)
				var color = sample_gradient(densityGradient, densityError)
				color.a = 0.3
				draw_circle(Vector2i(i, j) * s, s, color)
			
	var selected_particles = spatialLookup.get_particle_indices(get_global_mouse_position())
	
	for i in range(particles.size()):
		var speedL = inverse_lerp(5, 200, particles[i].velocity.length())
		draw_circle(particles[i].position, particleRadius, sample_gradient(speedGradient, speedL))
		
		
func sample_gradient(gradient: Gradient, l : float):
	return gradient.sample(l)
		

func calculate_density(pos: Vector2):
	var density = 0
	
	for particleIndex in spatialLookup.get_particle_indices(pos):
		var dst = pos.distance_to(particles[particleIndex].predictedPosition)
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
		var dst = pos.distance_to(particle.predictedPosition)
		var influence = SmoothingFunction.smoothing_kernel(smoothingRadius, dst)
		property += particle.property * influence / density
		
	return property
	
	
func calculate_shared_pressure(particleA : Particle, particleB : Particle):
	var pressureA = convert_density_to_pressure(particleA.density)
	var pressureB = convert_density_to_pressure(particleB.density)
	
	return (pressureA + pressureB) / 2

	
func calculate_pressure_force(particle: Particle):
	var pressureForce = Vector2.ZERO
	
	for otherParticleIndex in spatialLookup.get_particle_indices(particle.predictedPosition):
		var pos = particle.predictedPosition
		var otherParticle = particles[otherParticleIndex]
		if otherParticle.predictedPosition == pos: continue
		
		var dst = pos.distance_to(otherParticle.predictedPosition)
		var dir = (otherParticle.predictedPosition - pos) / dst

		var influence = SmoothingFunction.smoothing_kernel_derivative(smoothingRadius, pos.distance_to(otherParticle.predictedPosition))
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
	var predictedPosition: Vector2
	var velocity: Vector2 = Vector2.ZERO
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
	
	func update_predicted_position(delta: float):
		predictedPosition = handle_collision(position + velocity * 1 / 20)
	
	func update_position(delta : float):
		position += velocity * delta
		position = handle_collision(position)
		
		
	func update_densities():
		density = simulation.calculate_density(predictedPosition)
		
		
		
		
	func handle_collision(pos: Vector2):
		if pos.y > simulation.viewportSize.y - simulation.particleRadius:
			velocity.y *= -1 * simulation.damping
			pos.y = simulation.viewportSize.y - simulation.particleRadius
			
		if  pos.y < 0 + simulation.particleRadius:
			velocity.y *= -1 * simulation.damping
			pos.y = 0 + simulation.particleRadius
	
		if pos.x > simulation.viewportSize.x - simulation.particleRadius:
			velocity.x *= -1 * simulation.damping
			pos.x = simulation.viewportSize.x - simulation.particleRadius
			
		if  pos.x < 0 + simulation.particleRadius:
			velocity.x *= -1 * simulation.damping
			pos.x = 0 + simulation.particleRadius
		return pos
	
