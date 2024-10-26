@tool
class_name Epub extends RefCounted

var epub_file: String
var opf_path: String
var opf_root: OpfRoot


var Title
var Language
var Description
var Series
var Genres
var PublicationDate
var ModificationDate
var Collections

func _init(_epub_file: String) -> void:
	self.epub_file = _epub_file

	var reader := ZIPReader.new()
	if reader.open(self.epub_file) == OK:
		for file in reader.get_files():
			if file.ends_with(".opf"):
				self.opf_path = file
				var opf_data: PackedByteArray = reader.read_file(self.opf_path)
				
				if opf_data != null:
					self.opf_root = OpfRoot.from_buffer(opf_data)
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





	#func _get_elements():
		#return
#
#
	#func _get_element():
#
#
		##ElementTree.SubElement(self.xml_metadata, "meta", attrib={"refines": collection_id, "property": "display-seq"}).text = str(display_seq)
#
#
