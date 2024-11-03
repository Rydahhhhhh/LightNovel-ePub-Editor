class_name DescriptionField extends EpubProperty.TextProperty

const name = "EpubDescription"

func _init(_root: XMLTree) -> void:
	super(_root)
	self.node = self.find_or_create("dc:description")
