@tool
class_name Epub extends RefCounted

var opf_path: String
var epub_file: String
var xml_root: XMLTree
var _metadata: Metadata

# I wish there was a better way to add autocompletion
var title: String: get = _get_title, set = _set_title

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
	return ""

func _set_title(to: String) -> void:
	return

# ====================================================== #
#                      END OF FILE                       #
# ====================================================== #
