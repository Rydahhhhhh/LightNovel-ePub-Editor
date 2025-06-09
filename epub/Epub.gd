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
var series_index: String: get = _get_series_index, set = _set_series_index
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

func save(destination: String, format := false, overwrite := false) -> int:
	if not overwrite and FileAccess.file_exists(destination):
		return ERR_ALREADY_EXISTS
	
	var reader := ZIPReader.new()
	var writer := ZIPPacker.new()
	
	var reader_open_err := reader.open(self.epub_file)
	if reader_open_err != OK:
		return reader_open_err
	
	var writer_open_err := writer.open(destination)
	if writer_open_err != OK:
		return writer_open_err
	
	if format:
		self._metadata.format()
	
	for file in reader.get_files():
		var writer_start_err := writer.start_file(file)
		if writer_start_err != OK:
			return writer_start_err
		
		var writer_write_err := FAILED
		if file.ends_with(".opf"):
			writer_write_err = writer.write_file(self.xml_root.dump_buffer(true, 0, 2))
		else:
			writer_write_err = writer.write_file(reader.read_file(file))
		
		if writer_write_err != OK:
			return writer_write_err
		
	writer.close()
	reader.close()

	return OK

## Updates the ePub file with the edited data
func update_file() -> void:
	self.save(self.epub_file, true)
	return

# ====================================================== #
#                   SETTERS & GETTERS                    #
# ====================================================== #
func _to_string() -> String:
	self._metadata.format()
	return str(self._metadata.node)

func _get_title() -> String:
	return self._metadata.title.value

func _set_title(to: String) -> void:
	self._metadata.title.value = to
	return

func _get_series() -> String:
	return self._metadata.series.value

func _set_series(to: String) -> void:
	self._metadata.series.value = to
	return

func _get_description() -> String:
	return self._metadata.description.value

func _set_description(to: String) -> void:
	self._metadata.description.value = to
	return

func _get_language() -> String:
	return self._metadata.language.value

func _set_language(to: String) -> void:
	self._metadata.language.value = to
	return

func _get_publicationDate() -> String:
	return self._metadata.pub_date.value

func _set_publicationDate(to: String) -> void:
	self._metadata.pub_date.value = to
	return

func _get_title_sort() -> String:
	return self._metadata.title.sort_by

func _set_title_sort(to: String) -> void:
	self._metadata.title.sort_by = to
	return 

func _get_series_index() -> String:
	return self._metadata.series.index

func _set_series_index(to: String) -> void:
	self._metadata.series.index = to
	return 

func _get_rights() -> String:
	return self._metadata.rights.value

func _set_rights(to: String) -> void:
	self._metadata.rights.value = to
	return

func _get_lastModified() -> String:
	return self._metadata.mod_date.value

func _set_lastModified(to: String) -> void:
	self._metadata.mod_date.value = to
	return

func _get_identifier() -> String:
	return self._metadata.identifier.value

func _set_identifier(to: String) -> void:
	self._metadata.identifier.value = to
	return

func add_creator(name: String, role: String, sort: String = "") -> void:
	self._metadata.creators.add_creator(name, role, sort)
	return

func clear_creators() -> void:
	self._metadata.creators.clear()
	return

func add_genre(name: String) -> void:
	self._metadata.genres.add_genre(name)
	return

func _get_genres() -> Array[GenreField]:
	return self._metadata.genres.value

func _get_creators() -> Array[CreatorField]:
	return self._metadata.creators.value

func _get_collections() -> Array:
	return []
# ====================================================== #
#                      END OF FILE                       #
# ====================================================== #
