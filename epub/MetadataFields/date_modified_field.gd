class_name DateModifiedField extends EpubProperty.TextProperty

const name = "EpubIdentifier"

func _init(_root: XMLTree) -> void:
	super(_root)
	self.node = self.find_or_create("meta", null, {"property": "dcterms:modified"})
