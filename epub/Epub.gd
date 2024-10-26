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
	
	Title = self.opf_root.primary_title()

	return

func format_as_ln():
	return

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
