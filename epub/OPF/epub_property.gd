class_name EpubProperty extends RefCounted
## https://readium.org/architecture/streamer/parser/metadata.html


var xml_root: XMLTree
var xml_metadata: XMLTree

var value: Variant: get = _get_value, set = _set_value
var node: XMLTree
# ====================================================== #
#                        METHODS                         #
# ====================================================== #
func _get_value():
	push_warning("This should be overridden")
	return

func _set_value(to):
	push_warning("This should be overridden")
	return

# ====================================================== #
#                      BASE CLASSES                      #
# ====================================================== #
class ContentProperty extends EpubProperty:
	## Property that derives its value from the nodes content attribute.
	## Used in Epub 2.x format, as opposed to the preferred Epub 3.x
	## format hich uses text value instead
	func _get_value():
		return self.node.attributes["content"]
	
	func _set_value(to):
		self.node.attributes["content"] = to

class TextProperty extends EpubProperty:
	## Property that derives its value from the nodes text.
	## Used in Epub 3.x format. See, [ContentProperty] for further documentation.
	func _get_value():
		return self.node.text_content

	func _set_value(to):
		self.node.text_content = to 
	
class DoubleProperty extends EpubProperty:
	## In scenarios where both the Epub 2.x & 3.x cannot be condensed into a 
	## single node, we'll need nodes for both versions
	var _node_2x: XMLTree
	var _node_3x: XMLTree
	var _default_value
	
	func _get_value():
		# Since we'll be making sure both the 2.x & 3.x nodes will have the same
		# value it doesn't matter which node we'll get from, using the 3.x node
		# because the .text syntax is preferable
		return self._node_3x.text_content
	
	func _set_value(to):
		if to == null:
			to = ""
		self._node_2x.attributes["content"] = to
		self._node_3x.text_content = to
	
	func resolve() -> void:
		var temp_val = self._node_3x.text_content
		if temp_val == null or (temp_val is String and temp_val.is_empty()):
			temp_val = self._node_2x.attributes.get_or_add("content", _default_value)
		if temp_val == null or (temp_val is String and temp_val.is_empty()):
			temp_val = _default_value
		assert(temp_val == null or temp_val is String)
		self.value = temp_val

class GroupProperty extends EpubProperty:
	## When a property has a cardinality of zero or more (creators, collections, etc..)
	
	var epub_properties: Array[EpubProperty] = []
	
	func _get_value():
		var props = epub_properties.duplicate()
		props.make_read_only()
		return props
	
	func _get(property: StringName) -> Variant:
		for epub_prop in self.epub_properties:
			if epub_prop.value == property:
				return epub_prop
		return
	
	func _to_string() -> String:
		return str(self.epub_properties)

# ====================================================== #
#                       INHERITORS                       #
# ====================================================== #
# ====================================================== #
#                      END OF FILE                       #
# ====================================================== #
