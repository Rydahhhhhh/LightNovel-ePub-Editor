class_name Metadata extends RefCounted


# Although an Opf file is formatted as xml which uses the term 'node' 
# in the context of epub parsing I'm prefering to use the term 'element'
# see https://www.w3.org/TR/epub-33
enum CARDINALITY {ONLY_ONE}

const REQUIRED_ELEMENTS = ["dc:identifier", "dc:title", "dc:language"]

const ELEMENT_CLASSES_BY_TAG := {
	#"dc:identifier": _BaseElement,
	"dc:title": _Title,
	#"dc:language": _BaseElement,
	#"dc:contributor": _BaseElement,
	#"dc:coverage": _BaseElement,
	#"dc:creator": _BaseElement,
	#"dc:date": _BaseElement,
	#"dc:format": _BaseElement,
	#"dc:publisher": _BaseElement,
	#"dc:relation": _BaseElement,
	#"dc:rights": _BaseElement,
	#"dc:source": _BaseElement,
	#"dc:subject": _BaseElement,
	#"dc:type": _BaseElement,
	#"meta": _Meta
}

var elements_by_id := {}

var elements_by_tag := {
	"dc:title": [],
	#"dc:creator": [],
	#"dc:rights": [],
	#"dc:identifier": [],
	#"dc:language": [],
	#"dc:date": [],
	#"dc:publisher": [],
	#"dc:subject": [],
	#"dc:type": [],
	#"dc:source": [],
	#"meta": []
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
	
	#for meta_element: _BaseElement in self.elements_by_tag["meta"]:
		#if meta_element.element.attributes.has("refines"):
			#var refines: String = meta_element.element.attributes["refines"]
			#if refines.begins_with("#"):
				#refines = refines.substr(1)
			#
			#if self.elements_by_id.has(refines):
				#var refined_element: _BaseElement = self.elements_by_id[refines]
				#refined_element.attach_refine(meta_element)
			#else:
				#push_error("refining nothing")
	print('what')
	return 

func _add_element(xml_element) -> void:
	var tag = xml_element.tag
	var element_class = ELEMENT_CLASSES_BY_TAG[tag]
	var metadata_element = element_class.new(xml_element)
	
	self.elements_by_tag[tag].append(metadata_element)
	return

class _Title extends RefCounted:
	var Cardinality = Metadata.CARDINALITY.ONLY_ONE
	
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




func format() -> void:
	var core_element := []
	var refine_element := []
	var collection := []
	var calibre := []
	
	core_element.append(self.title.element)
	refine_element.append(self.title["title-type_element"].element)
	refine_element.append(self.title["sort_by_element"]._element_3x)
	
	calibre.append(self.title["sort_by_element"]._element_2x)
	
	for creator: CreatorField in self.creators.value:
		core_element.append(creator.element)
		refine_element.append(creator["role_element"].element)
		refine_element.append(creator["sort_by_element"].element)
	
	core_element.append(self.identifier.element)
	core_element.append(self.language.element)
	core_element.append(self.publisher.element)
	core_element.append(self.rights.element)
	core_element.append(self.pub_date.element)
	core_element.append(self.description.element)
	
	
	collection.append(self.series._element_3x)
	collection.append(self.series["collection-type_element"].element)
	collection.append(self.series["index_element"]._element_3x)
	
	calibre.append(self.series._element_2x)
	calibre.append(self.series["index_element"]._element_2x)
	
	#var sigil := self.find("meta", null, {"name": "Sigil version"})
	#if sigil:
		#calibre.append(sigil)
	
	self.element.comments = []
	
	var i := 0
	
	self.element.add_comment("Core Bibliographic Metadata", i)

	for a_element: XMLTree in core_element:
		a_element.index = i
		i += 1
	
	self.element.add_comment(XMLTree.BLANK, i)
	self.element.add_comment("Subjects", i)
	for genre: GenreField in self.genres.value:
		genre.element.index = i
		i += 1
	
	self.element.add_comment(XMLTree.BLANK, i)
	self.element.add_comment("Refined Metadata for Title and Creators", i)
	
	for a_element: XMLTree in refine_element:
		a_element.index = i
		i += 1
	
	self.element.add_comment(XMLTree.BLANK, i)
	self.xml_metadata.add_comment("Modified Date", i)
	self.mod_date.element.index = i
	i += 1
	
	#var cover := self.find("meta", null, {"name": "cover"})
	#if cover:
		#self.element.add_comment(XMLTree.BLANK, i)
		#self.xml_metadata.add_comment("Cover Image", i)
		#cover.index = i
		#i += 1
	
	self.element.add_comment(XMLTree.BLANK, i)
	self.xml_metadata.add_comment("Series and Collection Metadata", i)
	
	for a_element: XMLTree in collection:
		a_element.index = i
		i += 1
	
	self.element.add_comment(XMLTree.BLANK, i)
	self.xml_metadata.add_comment("Calibre-specific Metadata", i)
	
	for a_element: XMLTree in calibre:
		a_element.index = i
		i += 1
	
	#self.element.add_comment(XMLTree.BLANK, i)
	#self.xml_metadata.add_comment("Unsorted", i)
	
	return

#class _BaseElement extends RefCounted:
	#func _get_element_attributes() -> Array:
		#return []
#
	#var element: XMLTree
	#var refiners := {}
	#
	#func _init(_element: XMLTree) -> void:
		#self.element = _element
		#return
	#
	#func _to_string() -> String:
		#return str(self.element)
	#
	#func attach_refine(meta_element: _BaseElement):
		#var refine_property: Variant  = meta_element.get("property")
		#if refine_property == null:
			#push_error("idk")
			#return
		#
		#var id_as_refine = func() -> String: 
			#assert(self.id is String)
			#return "#" + self.id
		#self.refiners[refine_property] = meta_element
		#return
	#
	#func _get(property: StringName) -> Variant:
		#if property in self._get_element_attributes():
			#return self.element.attributes[property]
		#return 
#
#class _DublinCore extends _BaseElement:
	#func _get_element_attributes() -> Array:
		#return super() + ["dir", "id"]
#
#class _Identifier extends _DublinCore:
	#pass
#class _Language extends _DublinCore:
	#pass
#
#class _Meta extends _BaseElement:
	#func _get_element_attributes() -> Array:
		#return super() + ["dir", "id", "property", "refines", "scheme", "xml:lang"]
