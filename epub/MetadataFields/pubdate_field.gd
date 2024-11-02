class_name PubDateField extends EpubProperty.TextProperty

const name = "EpubPubDate"

func _init(_root: XMLTree) -> void:
	super(_root)
	self.node = self.find_or_create("dc:date")
