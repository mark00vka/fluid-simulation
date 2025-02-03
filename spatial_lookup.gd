class_name SpatialLookup

const offsets = [Vector2i(-1, -1), Vector2i(0, -1),Vector2i(+1, -1),
				Vector2i(-1, 0),Vector2i(0, 0),Vector2i(0, +1),
				Vector2i(-1, +1),Vector2i(+1, 0),Vector2i(+1, +1)]

var spatialLookup: Array[Array]
var spatialIndices: Array[int]
var simulation : Simulation


func global_to_cell(global_coords:Vector2):
	return Vector2i(global_coords / simulation.smoothingRadius)


func get_cell_key(coords:Vector2):
	var cell_coords = global_to_cell(coords)
	return coords_to_cell_key(cell_coords)
	
	
func coords_to_cell_key(cell_coords: Vector2i):
	const m = 1009
	const n = 1013
	var hash = cell_coords.x * m + cell_coords.y * n
	return hash % simulation.particles.size()


func get_neighbor_cell_keys(coords: Vector2):
	var cell_coords = global_to_cell(coords)
	var cell_keys = []
	
	for offset in offsets:
		cell_keys.append(coords_to_cell_key(cell_coords + offset))
	
	return cell_keys


func generateSpatialLookup():
	spatialLookup.resize(simulation.particles.size())
	spatialIndices.resize(simulation.particles.size())
	spatialIndices.fill(-1)
	
	for i in range(simulation.particles.size()):
		var particle = simulation.particles[i]
		spatialLookup[i] = [get_cell_key(particle.predictedPosition), i]
	spatialLookup.sort_custom(func (a, b): return a[0] < b[0])
	
	var prev = -1
	for i in range(spatialLookup.size()):
		var ind = spatialLookup[i][0]
		if prev != ind:
			prev = ind
			spatialIndices[ind] = i 

func get_indices_in_cell(cell_key: int):
	var indices = []
	var size = spatialLookup.size()
	var start = spatialIndices[cell_key]
	
	while start < size && spatialLookup[start][0] == cell_key:
		indices.append(spatialLookup[start][1])
		start += 1
	return indices

func get_particle_indices(coords:Vector2):
	var cell_keys = get_neighbor_cell_keys(coords)
	var indices = []
	
	for cell_key in cell_keys:
		indices.append_array(get_indices_in_cell(cell_key))
	
	return indices
