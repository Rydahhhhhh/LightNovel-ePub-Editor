class_name XMLUtils
## From https://github.com/elenakrittik/GodotXML 

static func cleanup_double_blankets(xml: PackedByteArray) -> PackedByteArray:
	# XMLParser is again "incorrect" and duplicates nodes due to double blank escapes
	# https://github.com/godotengine/godot/issues/81896#issuecomment-1731320027

	var rm_count := 0 # How much elements (blankets) to remove from the source
	var idx := xml.size() - 1

	# Iterate in reverse order. This matters for perf because otherwise we
	# would need to do a double .reverse() and remove elements from the start
	# of the array, both of which are quite expensive
	while idx >= 0:
		if xml[idx] in [9, 10, 13]: # [\t, \n, \r]
			rm_count += 1
			idx -= 1
		else:
			break

	# Remove blankets
	while rm_count > 0:
		xml.remove_at(xml.size() - 1)
		rm_count -= 1

	return xml
