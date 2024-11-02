class_name GenreField extends EpubProperty.TextProperty
const name = "EpubGenre"


func _init(creator_node: XMLTree) -> void:
	super(creator_node.root)
	
	self.node = creator_node
	
	return
