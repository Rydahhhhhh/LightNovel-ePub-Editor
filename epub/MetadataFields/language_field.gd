class_name LanguageField extends EpubProperty.TextProperty

const name = "EpubLanguage"

func _init(_root: XMLTree) -> void:
	super(_root)
	self.node = self.find_or_create("dc:language")
