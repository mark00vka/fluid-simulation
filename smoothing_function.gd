class_name SmoothingFunction

		
static func smoothing_kernel(radius: float, dst: float):
	if dst >= radius: return 0
	var volume = PI * pow(radius, 4) / 600
	return (radius - dst) * (radius - dst) / volume

	
static func smoothing_kernel_derivative(radius: float, dst: float):
	if dst >= radius: return 0
	var s = - 1200 / PI / pow(radius, 4)
	return s * (radius - dst)
