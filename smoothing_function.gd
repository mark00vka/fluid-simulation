class_name SmoothingFunction

		
static func smoothing_kernel(radius: float, dst: float):
	if dst >= radius: return 0
	var volume = PI * pow(radius, 3) / 6
	return (radius - dst) * (radius - dst) / volume

	
static func smoothing_kernel_derivative(radius: float, dst: float):
	if dst >= radius: return 0
	var s = - 12 / PI / pow(radius, 3)
	return s * (radius - dst)
