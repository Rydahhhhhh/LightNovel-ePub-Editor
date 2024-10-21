@tool
class_name Epub extends RefCounted

var epub_file: String
var opf_path: String
var xml: EasyXml

var _title
var _language
var _description
var _series
var _genres
var _publicationDate
var _modificationDate
var _collections

func _init(_epub_file: String) -> void:
	self.epub_file = _epub_file

	var reader := ZIPReader.new()
	if reader.open(self.epub_file) == OK:
		for file in reader.get_files():
			if file.ends_with(".opf"):
				self.opf_path = file
				var opf_data: PackedByteArray = reader.read_file(self.opf_path)
				
				if opf_data != null:
					self.xml = EasyXml.new(opf_data)
	reader.close()
	
	if self.xml == null:
		print('failed')
		return
	
	self._title = EpubPropertyTitle.new(self.xml)
	self._language = EpubPropertyLanguage.new(self.xml)
	self._description = EpubPropertyDescription.new(self.xml)
	self._series = EpubPropertySeries.new(self.xml)
	self._genres = EpubPropertySubjects.new(self.xml)
	self._publicationDate = EpubPropertyPublicationDate.new(self.xml)
	self._modificationDate = EpubPropertyModificationDate.new(self.xml)
	#self._collections = EpubPropertyCollections.new(self.xml)
	return

func _get(property: StringName) -> Variant:
	var internal_prop = "_%s" % property.to_lower()
	if internal_prop in self:
		return self.get(internal_prop).text
	return

func _set(property: StringName, value: Variant) -> bool:
	var internal_prop = "_%s" % property.to_lower()
	if internal_prop in self:
		self.get(internal_prop).text = value
		return true
	return false

func save(destination = null, overwrite: bool = false):
	if not overwrite and FileAccess.file_exists(destination):
		return
	
	var reader := ZIPReader.new()
	var writer := ZIPPacker.new()
	
	if reader.open(self.epub_file) == OK and writer.open(destination) == OK:
		for file in reader.get_files():
			writer.start_file(file)
			
			if file.ends_with(".opf"):
				writer.write_file(self.xml.root.dump_buffer(true, 0, 2))
			else:
				writer.write_file(reader.read_file(file))
			
		writer.close()
		reader.close()
	
	return

class EpubPropertyBase:
	var xml: EasyXml
	
	func _init(xml_root: EasyXml) -> void:
		self.xml = xml_root
		return

	func find(tag, attrs=[], kv_attrs={}, content=null):
		return self.xml.find(tag, attrs, kv_attrs, content)

	func findall(tag, attrs=[], kv_attrs={}, content=null):
		return self.xml.findall(tag, attrs, kv_attrs, content)

class EpubProperty extends EpubPropertyBase:
	var text: get = _text, set = set_text
	var element: get = _element
	var epub_version: get = _epub_version
	var element_id: get = _element_id
	
	func _text():
		if self.element == null:
			return null
		return self.element.content
	
	func set_text(new_text):
		self.element.content = new_text
		return

	func _element():
		if element != null:
			return element
		element = _get_element()
		return element
	
	func _get_element():
		assert(false)
		return
	
	func _epub_version():
		return 3 if self.element_id != null else 2

	func _element_id():
		var element_id = self.element.get("id")
		
		if element_id != null:
			return "#" + element_id
		return null
	
	func _to_string() -> String:
		return self.text
	
class EpubGroupProperty extends EpubPropertyBase:
	var elements: get = _elements
	
	func _get(property: StringName) -> Variant:
		if property in self.elements:
			return self.elements[property]
		return
	
	func _elements():
		if elements != null:
			return elements
		elements = _elements()
		return elements
	
	func _get_elements():
		assert(false)
		return

	func epub_version(key):
		return self.elements[key].epub_version

	func element_id(key):
		return self.elements[key].element_id

class EpubPropertyTitle extends EpubProperty:
	var sort_element: get = _sort_element
	var sort: get = _sort, set = _set_sort
	
	func _get_element():
		# Epub 2
		# The title element treated as the 'main' is the first one
		var xml_title = self.find("dc:title")
		if xml_title == null:
			# Title elements are mandatory for epub files
			assert(false, "No title elements TODO")

		# Epub 3
		# The title element treated as the 'main' is the one the that is refined by a meta element
		# with text main. Find the meta element that refines a title with property 'title-type' and text 'main'
		# then it's refine id will reference the title element that should be treated as 'main'
		var xml_titletype_main = self.find("meta", [], {"property": "title-type"}, "main")
		# If we find the element, but it doesn't have the "refines" property
		# the epub isn't correctly parsed and is probably broken, will default to epub 2 behavior in that case
		# Should probably emit a warning but, I doubt an error needs to be raised
		if xml_titletype_main != null:
			var xml_title_id: String = xml_titletype_main.get("refines")
			if xml_title_id != null:
				xml_title = self.find("dc:title", [], {"id": xml_title_id.substr(1)})
		return xml_title

	func _sort_element():
		if self.element_id != null:
			return self.find("meta", [], {"refines": self.element_id, "property": "file-as"})
		return self.find("meta", [], {"name": "calibre:title_sort"})

	func _sort():
		if self.sort_element != null:
			if self.epub_version == 3:
				return self.sort_element.text
			return self.sort_element.attributes.get("content")
		return null

	func _set_sort(new_sort):
		if self.sort_element != null:
			if self.epub_version == 3:
				self.sort_element.text = new_sort
			else:
				self.sort_element.attributes.set("content", new_sort)
		return

class EpubPropertySeries extends EpubProperty:
	func _get_element():
		var xml_series = self.find("meta", [], {"property": "belongs-to-collection"})
		if xml_series == null or xml_series.get("id") == null:
			xml_series = self.find("meta", [], {"name": "calibre:series"})
		return xml_series

	func index_element():
		if self.epub_version == 3:
			return self.find("meta", [], {"refines": self.element_id, "property": "group-position"})
		return self.find("meta", [], {"name": "calibre:series_index"})

	func sort_element():
		if self.epub_version == 3:
			return self.find("meta", [], {"refines": self.element_id, "property": "file-as"})
		return null

	func identifier():
		if self.epub_version == 3:
			return self.find("meta", [], {"refines": self.element_id, "property": "dcterms:identifier"})
		return null

class EpubPropertyDescription extends EpubProperty:
	func _get_element():
		return self.find("dc:description")

class EpubPropertyLanguage extends EpubProperty:
	func _get_element():
		return self.find("dc:language")

class EpubPropertySubjects extends EpubProperty:
	func _get_element():
		return self.findall("dc:subject")

class EpubPropertyModificationDate extends EpubProperty:
	func _get_element():
		# For epub 3 it's the meta element whose property attribute has the value dcterms:modified
		var xml_modification_date = self.find("meta", [], {"property": "dcterms:modified"})
		if xml_modification_date == null:
			# For epub 2 it's the <dc:date> element whose opf:event attribute has the value modification
			xml_modification_date = self.find("dc:date", [], {"opf:event": "modification"})
		return xml_modification_date

class EpubPropertyPublicationDate extends EpubProperty:
	func _get_element():
		for element in self.findall("dc:date"):
			if element.get("opf:event") == null:
				return element
		return
#
#class EpubPropertyCollections extends EpubGroupProperty:
	#func _get_elements():
		#var xml_collections = {}
		#for refine in self.findall("meta", [], {"property": "title-type"}, "collection"):
			#var collection_id = refine.get("refines")
			#if collection_id != null:
				#var xml_collection = self.find("dc:title", [], {"id": collection_id.substr(1)})
				#xml_collections[xml_collection.text] = EpubPropertyCollection.new(self.xml, xml_collection)
#
		#return xml_collections
#
	#func add(collection_name: String, display_seq: int):
		#if collection_name.to_lower() in self.elements.keys().map(func(s: String): return s.to_lower()):
			#assert(false, "Collection already exists")
#
		#var collection_id = "#{collection_name}Collection".format({"collection_name": collection_name})
		#
		#var xml_title = XMLNode.new()
		#xml_title.name = "dc:title"
		#xml_title.attributes = {"id": collection_id}
		#xml_title.content = collection_name
		#self.find("metadata").children.append(xml_title)
		
		#ElementTree.SubElement(self.xml_metadata, "meta", attrib={"refines": collection_id, "property": "title-type"})
		#ElementTree.SubElement(self.xml_metadata, "meta", attrib={"refines": collection_id, "property": "display-seq"}).text = str(display_seq)

		#self.elements[collection_name] = EpubPropertyCollection(self.xml, xml_title)
		#return

#
#class EpubPropertyCollection extends EpubProperty:
	#func _init(xml_root, collection_element):
		#super(xml_root)
		##self._element = collection_element
		#return
#
	#func _get_element():
		#return self._element
#
	#func sequence_element():
		#return self.find("meta", {"refines": self.element_id, "property": "display-seq"})
#
	#func remove(collection_name):
		#pass
		##raise NotImplementedError("Remove Collection")
#
	#func set_name(name):
		#pass
		##raise NotImplementedError("Edit Collection")
#
	#func set_index():
		#return
