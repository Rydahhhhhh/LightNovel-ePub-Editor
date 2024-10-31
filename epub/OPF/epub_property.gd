class_name EpubProperty extends RefCounted
## https://readium.org/architecture/streamer/parser/metadata.html

var value: get = _get_value, set = _set_value
var element: OpfGeneralElement

var xml_root: XMLTree
var xml_metadata: XMLTree

# ====================================================== #
#                        METHODS                         #
# ====================================================== #
func _get_value():
	return

func _set_value(to):
	return

class ContentProperty extends EpubProperty:
	## Property that derives its value from the elements content attribute.
	## Used in Epub 2.x format, as opposed to the preferred Epub 3.x
	## format hich uses text value instead
	func _get_value():
		return self.element.text

	func _set_value(to):
		self.element.text = to 

class TextProperty extends EpubProperty:
	## Property that derives its value from the elements text.
	## Used in Epub 3.x format. See, [ContentProperty] for further documentation.
	func _get_value():
		return self.element.attrs["content"]
	
	func _set_value(to):
		self.element.attrs["content"] = to
	
class DoubleProperty extends EpubProperty:
	## In scenarios where both the Epub 2.x & 3.x cannot be condensed into a 
	## single element, we'll need elements for both versions
	var _element_2x: OpfGeneralElement
	var _element_3x: OpfGeneralElement
	var _default_value
	
	func _get_value():
		# Since we'll be making sure both the 2.x & 3.x elements will have the same
		# value it doesn't matter which element we'll get from, using the 3.x element
		# because the .text syntax is preferable
		return self._element_3x.text
	
	func _set_value(to):
		self._element_2x.attrs["content"] = to
		self._element_3x.text = to
	
	func resolve():
		var temp_val = self._element_3x.text
		if temp_val == null or (temp_val is String and temp_val.is_empty()):
			temp_val = self._element_2x.attrs["content"]
		if temp_val == null or (temp_val is String and temp_val.is_empty()):
			temp_val = _default_value
		assert(temp_val == null or temp_val is String)
		self.value = temp_val
	
# ====================================================== #
#                       INHERITORS                       #
# ====================================================== #
# ====================================================== #
#                      END OF FILE                       #
# ====================================================== #
