class_name CreatorsField extends EpubProperty.GroupProperty

const name = "EpubCreators"

func _init(_root: XMLTree) -> void:
	super(_root)
	
	for node in self.find_all("dc:creator"):
		var creator := CreatorField.new(node)
		creator.group = self
		self.epub_properties.append(creator)

func add_creator(name: String, role: String, sort: String = ""):
	var creator: CreatorField = CreatorField.new(
		XMLTree.new(self.xml_metadata, "dc:creator", name, {})
	)
	creator.group = self
	creator.role = role
	creator.sort_by = sort
	
	self.epub_properties.append(creator)
	return
