class_name GenresField extends EpubProperty.GroupProperty

const name = "EpubGenres"

func _init(_root: XMLTree) -> void:
	super(_root)
	
	for node in self.find_all("dc:subject"):
		var genre := GenreField.new(node)
		genre.group = self
		self.epub_properties.append(genre)

func add_genre(name: String):
	for genre in self.epub_properties:
		if genre.value.to_lower() == name.to_lower():
			#push_warning("already exists")
			return 
	
	var genre: GenreField = GenreField.new(
		XMLTree.new(self.xml_metadata, "dc:subject", name.capitalize(), {})
	)
	genre.group = self
	
	self.epub_properties.append(genre)
	return
