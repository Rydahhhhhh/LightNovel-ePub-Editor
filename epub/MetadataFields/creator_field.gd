class_name CreatorField extends EpubProperty.TextProperty
const name = "EpubCreator"

var sort_by: String:
	get():
		return self["sort_by_node"].value
	set(to):
		self["sort_by_node"].value = to

var role: String:
	get():
		return self._sub_properties["role"].value
	set(to):
		self._sub_properties["role"].value = to

func _init(creator_node: XMLTree) -> void:
	super(creator_node.root)
	
	self.node = creator_node
	
	if self.id == null:
		self.id = self.node.generate_id()
	
	self.add_subproperty("sort_by",
		TextProperty.from_nodes(
			self.xml_root,
			self.find_or_create("meta", null, {"refines": self.id, "property": "file-as"})
		).refines(self)
	)
	self.add_subproperty("role",
		TextProperty.from_nodes(
			self.xml_root,
			self.find_or_create("meta", null, {"refines": self.id, "property": "role"})
		).refines(self)
	)
	return
