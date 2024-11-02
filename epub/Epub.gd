@tool
class_name Epub extends RefCounted

var opf_path: String
var epub_file: String
var xml_root: XMLTree
var _metadata: Metadata

# I wish there was a better way to add autocompletion
var title: String: get = _get_title, set = _set_title
var title_sort: String: get = _get_title_sort, set = _set_title_sort
var creators: Array: get = _get_creators
var series: String: get = _get_series, set = _set_series
var series_index: int: get = _get_series_index, set = _set_series_index
var description: String: get = _get_description, set = _set_description
var genres: Array: get = _get_genres
var language: String: get = _get_language, set = _set_language
var publicationDate: String: get = _get_publicationDate, set = _set_publicationDate
var collections: Array: get = _get_collections
var rights: String: get = _get_rights, set = _set_rights
var lastModified: String: get = _get_lastModified, set = _set_lastModified
var identifier: String: get = _get_identifier, set = _set_identifier

func _init(_epub_file: String) -> void:
	self.epub_file = _epub_file
	
	var reader := ZIPReader.new()
	if reader.open(self.epub_file) == OK:
		for file in reader.get_files():
			if file.ends_with(".opf"):
				self.opf_path = file
				var opf_data: PackedByteArray = reader.read_file(self.opf_path)
				if opf_data != null:
					self.xml_root = Xml.parse_buffer(opf_data)
	reader.close()
	
	if self.xml_root == null:
		print('failed')
		return
	
	self._metadata = Metadata.new(self.xml_root)
	print("DONE")
	return

func save(destination = null, overwrite: bool = false):
	if not overwrite and FileAccess.file_exists(destination):
		return
	
	var reader := ZIPReader.new()
	var writer := ZIPPacker.new()
	
	if reader.open(self.epub_file) == OK and writer.open(destination) == OK:
		self._metadata.format()
		for file in reader.get_files():
			writer.start_file(file)
			
			if file.ends_with(".opf"):
				writer.write_file(self.xml_root.dump_buffer(true, 0, 2))
			else:
				writer.write_file(reader.read_file(file))
			
		writer.close()
		reader.close()
	
	return


func _to_string() -> String:
	self._metadata.format()
	return str(self._metadata.node)

func _get_title():
	return self._metadata.title.value

func _set_title(to: String):
	self._metadata.title.value = to
	return

func _get_series():
	return self._metadata.series.value

func _set_series(to):
	self._metadata.series.value = to
	return

func _get_description():
	return self._metadata.description.value

func _set_description(to):
	self._metadata.description.value = to
	return

func _get_language():
	return self._metadata.language.value

func _set_language(to):
	self._metadata.language.value = to
	return

func _get_publicationDate():
	return self._metadata.pub_date.value

func _set_publicationDate(to):
	self._metadata.pub_date.value = to
	return

func _get_title_sort():
	return self._metadata.title.sort_by
func _set_title_sort(to):
	self._metadata.title.sort_by = to
	return 


func _get_series_index():
	return self._metadata.series.index
func _set_series_index(to):
	print('setters triggered')
	self._metadata.series.index = to
	return 

func _get_rights():
	return self._metadata.rights.value
func _set_rights(to):
	self._metadata.rights.value = to
	return

func _get_lastModified():
	return self._metadata.mod_date.value

func _set_lastModified(to):
	self._metadata.mod_date.value = to
	return

func _get_identifier():
	return self._metadata.identifier.value

func _set_identifier(to):
	self._metadata.identifier.value = to
	return

func add_creator(name: String, role: String, sort: String = ""):
	self._metadata.creators.add_creator(name, role, sort)
	return

func clear_creators():
	self._metadata.creators.clear()
	return

func add_genre(name: String):
	self._metadata.genres.add_genre(name)
	return

func _get_genres():
	return self._metadata.genres.value

func _get_creators():
	return self._metadata.creators.value

func _get_collections():
	return []
# ====================================================== #
#                      END OF FILE                       #
# ====================================================== #
