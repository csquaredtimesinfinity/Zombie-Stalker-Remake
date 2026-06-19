extends Node

class_name UUID4

static func uuid4() -> String:
	const uuid_chars = "0123456789abcdef"
	var result := ""
	for i in range(32):
		if i in [8, 12, 16, 20]:
			result += "-"
		if i == 12:
			result += "4"
		elif i == 16:
			# Variant bits
			var r := randi() % 16
			r = (r & 0x3) | 0x8 
			result += uuid_chars[r]
		else:
			var r := randi() % 16
			result += uuid_chars[r]
	return result
