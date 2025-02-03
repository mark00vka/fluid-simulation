class_name SpatialLookup

var lookupSize = 20

var spatialLookup: Array[Array]
var spatialIndices: Array[int]
var simulation : Simulation


func global_to_cell(global_coords:Vector2):
	return Vector2i(global_coords / simulation.smoothingRadius)

func get_cell_key(coords:Vector2):
	var cell_coords = global_to_cell(coords)
	var m = 1009
	var n = 1013
	var hash = cell_coords.x * m + cell_coords.y * n
	return hash % lookupSize

func generateSpatialLookup():
	spatialLookup.resize(simulation.particles.size())
	spatialIndices.resize(lookupSize)
	spatialIndices.fill(-1)
	
	for i in range(simulation.particles.size()):
		var particle = simulation.particles[i]
		spatialLookup[i] = [get_cell_key(particle.position), i]
	spatialLookup.sort_custom(func (a, b): return a[0] < b[0])
	
	var prev = -1
	for i in range(spatialLookup.size()):
		var ind = spatialLookup[i][0]
		if prev != ind:
			prev = ind
			spatialIndices[ind] = i 


func get_particle_indices(coords:Vector2):
	var cell_key = get_cell_key(coords)
	var start = spatialIndices[cell_key]
	var indices = []
	var size = spatialLookup.size()
	
	while start < size && spatialLookup[start][0] == cell_key:
		indices.append(spatialLookup[start][1])
		start += 1
	return indices
