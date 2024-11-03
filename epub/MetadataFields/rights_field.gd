class_name RightsField extends EpubProperty.TextProperty

const name = "EpubRights"

func _init(_root: XMLTree) -> void:
	super(_root)
	self.node = self.find_or_create("dc:rights")
