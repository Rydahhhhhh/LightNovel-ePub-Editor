class_name Metadata extends RefCounted

# Although an Opf file is formatted as xml which uses the term 'node' 
# in the context of epub parsing I'm prefering to use the term 'element'
# see https://www.w3.org/TR/epub-33
const REQUIRED_ELEMENTS = ["dc:title"]

const ELEMENT_CLASSES_BY_TAG := {
	"dc:title": _Title,
}

var elements_by_tag := {
	"dc:title": [],
}

var xml_metadata: XMLTree

var elem_title: _Title

func _init(root: XMLTree) -> void:
	self.xml_metadata = root.query_selector(XMLQuery.new("metadata"))
	
	for element in self.xml_metadata.children:
		if element.tag in self.elements_by_tag:
			self._add_element(element)
		else:
			push_error("Unknown tag")
	
	print('what')
	return 

func _add_element(xml_element) -> void:
	var tag = xml_element.tag
	var element_class = ELEMENT_CLASSES_BY_TAG[tag]
	var metadata_element = element_class.new(xml_element)
	
	self.elements_by_tag[tag].append(metadata_element)
	return

class _Title extends RefCounted:
	var attributes = [
		{"name": "dir", "optional": true},
		{"name": "id", "optional": true},
		{"name": "xml:lang", "optional": true}
	]
	
	func _init(_element: XMLTree) -> void:
		self.element = _element
		return
	
	func _to_string() -> String:
		return str(self.element)
