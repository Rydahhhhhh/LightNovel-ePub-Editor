class_name OpfGeneralElement extends OpfElement

var id:
	get():
		return self.attrs.get("id")
	set(to):
		self.attrs["id"] = to

var index:
	get():
		# Gonna use the node here because children creates new element instances so .find won't work
		# Should fix that eventually... somehow idk problem for future me
		return self.root.metadata.node.children.find(self.node)
	set(to):
		var own_node = self.root.metadata.node.children.pop_at(self.index)
		self.root.metadata.node.children.insert(to, own_node)

var root: OpfRoot


func _init(_node: XMLNode, _root: OpfRoot) -> void:
	super(_node)
	self.root = root

# ====================================================== #
#                        METHODS                         #
# ====================================================== #
## See [method OpfElement.find] for documentation.
func find(
	tag, 
	attrs: Array[String] = [], 
	kv_attrs: Dictionary = {}, 
	text = null
) -> OpfGeneralElement:
	return self.root.find(tag, attrs, kv_attrs, text)

## See [method OpfElement.findall] for documentation.
func findall(
	tag, 
	attrs: Array[String] = [], 
	kv_attrs: Dictionary = {}, 
	text = null
) -> Array[OpfElement]:
	return self.root.findall(tag, attrs, kv_attrs, text)


## Either finds the matching element or creates it if it doesn't exist
## See [method find] for parameter documentation.
func find_or_create(
	tag, 
	attrs: Array[String] = [], 
	kv_attrs: Dictionary = {}, 
	text = null
) -> OpfGeneralElement:
	
	var element = self.find(tag, attrs, kv_attrs, text)
	if element == null:
		element = self.root.metadata.create_child(tag, kv_attrs, text)
	
	return element

func id_exists(id: String):
	return len(self.findall(null, [], {"id": id})) == 0

# ====================================================== #
#                      END OF FILE                       #
# ====================================================== #
