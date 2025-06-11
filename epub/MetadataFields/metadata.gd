class_name Metadata extends RefCounted

signal test

# Although an Opf file is formatted as xml which uses the term 'node' 
# in the context of epub parsing I'm prefering to use the term 'element'
# see https://www.w3.org/TR/epub-33
const ATTRIBUTE_NOT_PRESENT = "_not_present_sentinel_"
const REQUIRED_ELEMENTS = ["dc:title"]

const ELEMENT_CLASSES_BY_TAG := {
	"dc:title": _Title,
}

var xml_metadata: XMLTree

func _init(root: XMLTree) -> void:
	# Locates the metadata element
	self.xml_metadata = root.query_selector(XMLQuery.new("metadata"))
	
	var elements_by_id := {
		
	}
	
	var meta_elements = []
	
	# Iterates through it's children
	for xml_element: XMLTree in self.xml_metadata.children:
		if xml_element.tag == "dc:title":
			var title_elem := _Title.new(xml_element)
			
			if title_elem.raw_id != null:
				elements_by_id[title_elem.raw_id] = title_elem
			
		if xml_element.tag == "meta":
			#if "id" in xml_element.attributes:
				#print(xml_element)
			meta_elements.append(xml_element)
	
	for xml_element in meta_elements:
		var meta_elem = _Meta.new(xml_element)
		
		if meta_elem.raw_refines in elements_by_id:
			elements_by_id[meta_elem.raw_refines].attach_refine(meta_elem)
		elif meta_elem.raw_refines != null:
			print(meta_elem)

	
	#print(JSON.stringify(titles[0], "\t"))

	return 

class _Element extends RefCounted:
	var attributes: get = _attrs
	var element: XMLTree;
	
	func _attrs():
		return []
	
	func _init(_element: XMLTree) -> void:
		self.element = _element
		
		return
	
	func _get(property: StringName) -> Variant:
		if property in self.attributes:
			return self.element.attributes.get(property, null)
		return
	
	func _set(property: StringName, value: Variant) -> bool:
		if property in self.attributes:
			return self.element.attributes.set(property, value)
		return false
	
	func _to_string() -> String:
		return str(self.element)
	
	static func unprefix(str: String, prefix):
		return str.substr(len(prefix)) if str.begins_with(prefix) else str 

class _Title extends _Element:
	var raw_id:
		get:
			if "id" in self:
				return unprefix(self.id, "#")
			return null
	
	func _attrs():
		return ["dir", "id", "xml:lang"]
	
	func _init(_element: XMLTree) -> void:
		super(_element)
		return
		
	func attach_refine(_meta: _Meta):
		#print(_meta.property)
		return
	
	

class _Meta extends _Element:
	var raw_refines:
		get:
			if "refines" in self:
				return unprefix(self.refines, "#")
			return null
	
	func _attrs():
		return ["dir", "id", "property", "refines", "scheme", "xml:lang"]
	
	func _init(_element: XMLTree) -> void:
		super(_element)
		if "property" not in self:
			## FUCK YOU CALBIBRE & SIGIL
			#push_error("property attribute is required on elements: 'meta'")
			pass
		
		return
