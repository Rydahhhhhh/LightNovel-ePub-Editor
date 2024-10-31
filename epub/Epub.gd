@tool
class_name Epub extends RefCounted

var epub_file: String
var opf_path: String
var xml_root: XMLTree


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
					self.xml_root = XMLTree.parse_buffer(opf_data)
	reader.close()
	
	if self.xml_root == null:
		print('failed')
		return
	
	self.title = EpubProperty.Title.new(self.xml_root)
	self.series = EpubProperty.Series.new(self.xml_root)
	#self.seriesIndex = EpubProperty.SeriesIndex.new(self.series)
	self.description = EpubProperty.Description.new(self.xml_root)
	self.language = EpubProperty.Language.new(self.xml_root)
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
				writer.write_file(self.opf_root.dump_buffer(true, 0, 2))
			else:
				writer.write_file(reader.read_file(file))
			
		writer.close()
		reader.close()
	
	return

# ====================================================== #
#                      END OF FILE                       #
# ====================================================== #
