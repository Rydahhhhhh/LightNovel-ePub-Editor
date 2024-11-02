class_name EpubProperty extends RefCounted
## https://readium.org/architecture/streamer/parser/metadata.html

var _sub_properties := {}

var xml_root: XMLTree
var xml_metadata: XMLTree

var value: Variant: get = _get_value, set = _set_value
var node: XMLTree
var group: GroupProperty
var _nodes: Array:
	get():
		var nodes: Array = [self.node]
		
		if self is DoubleProperty:
			nodes.append(self._node_2x)
			nodes.append(self._node_3x)
		
		return nodes

var id: get = _get_id, set = _set_id
var refine_id: get = get_refine_id

func _init(_xml_root: XMLTree) -> void:
	self.xml_root = _xml_root
	self.xml_metadata = self.find("metadata")

func _get_id():
	return self.node.attributes.get("id")

func _set_id(to):
	if self.id != to:
		assert(not self.xml_root.id_exists(to))
		self.node.attributes["id"] = to

func get_refine_id():
	var _refine_id = self.node.attributes.get("refines")
	if _refine_id == null:
		return null
	if _refine_id.begins_with("#"):
		return _refine_id.substr(1)
	return _refine_id

func refines(prop: EpubProperty) -> EpubProperty:
	
	for node: XMLTree in self._nodes:
		if node != null and node.attributes.has("refines"):
			node.bind_attribute("refines",  func():
				if prop.id == null:
					return null
				return "#" + prop.id
			)
	
	return self

## ====================================================== ##
##                        METHODS                         ##
## ====================================================== ##

## Removes it's [param node] and it's sub properties [param node's] from the tree
func remove(reason: String = "none"):
	if self.group != null:
		self.group.epub_properties.erase(self)
	
	self.node.parent = null
	
	for prop: EpubProperty in self._sub_properties.values():
		prop.remove()
	
	#print("removed: '", str(node), "' Reason: ", reason)
	
	while self.get_reference_count():
		self.unreference()

func add_subproperty(name: String, prop: EpubProperty):
	if name in self._sub_properties:
		push_error("subproperty '%s' already exists")
		return
	
	self._sub_properties[name] = prop
	return prop

func add_refiner(refiner: XMLTree) -> XMLTree:
	var fn = func(): return "#" + self.id
	
	refiner.bind_attribute("refines", fn)
	return refiner

static func clean(node: XMLTree) -> void:
	# Any node that could be removed from this are nodes that couldn't be properly parsed
	# due to poorly formatted xml inside the opf file. Such nodes would be created in the correct way 
	# if they couldn't be parsed, so this method is purely to 'clean' an opf file of redundant nodes.
	var prop = TextProperty.from_nodes(node, node)
	
	for meta_node in prop.find_all("meta"):
		var meta_prop = TextProperty.from_nodes(node, meta_node)
		if meta_prop.refine_id != null:
			if not node.id_exists(meta_prop.refine_id):
				meta_prop.remove("Refines nothing")
		
	return

# ================== #
#   Search methods   #
# ================== #
func find_or_create(
	tag: String, 
	text_content = null, 
	kv_attrs: Dictionary = {},
	attrs: Array[String] = []
) -> XMLTree:
	var node = self.find(tag, text_content, kv_attrs, attrs)
	if node == null:
		if text_content == null:
			text_content = ""
		node = XMLTree.new(xml_metadata, tag, text_content, kv_attrs)
	return node

func find(
	tag, 
	text_content = null, 
	kv_attrs: Dictionary = {},
	attrs: Array[String] = []
) -> XMLTree:
	return self.xml_root.query_selector(XMLQuery.new(tag, text_content, kv_attrs, attrs))

func find_all(
	tag, 
	text_content = null, 
	kv_attrs: Dictionary = {},
	attrs: Array[String] = []
) -> Array[XMLTree]:
	return self.xml_root.query_selector_all(XMLQuery.new(tag, text_content, kv_attrs, attrs))

# ================== #
#   Private methods  #
# ================== #
func _get_value():
	return null

func _set_value(to):
	return

func _get(property: StringName) -> Variant:
	# If a inheriting class doesn't have a name, use a default
	if property == "name":
		if self.value == null:
			return "EpubPropertyEmpty"
		return "EpubProperty"
	
	if "_node" in property:
		var prop = property.substr(0, len(property) - 5)
		if prop in self._sub_properties:
			return self._sub_properties[prop]
	
	return

func _set(property: StringName, value: Variant) -> bool:
	if property in self._sub_properties:
		self._sub_properties[property].value = value
		return true
	return false

func _to_string() -> String:
	var name = self.name
	
	var prop_str = ' {key}="{value}"'.format({"key": "value", "value": self.value})
	for prop_key in self._sub_properties:
		var prop_value = self._sub_properties.get(prop_key).value
		
		if prop_value is String:
			prop_value = prop_value.xml_escape(true)
		
		prop_str += ' {key}="{value}"'.format({"key": prop_key, "value": prop_value})
	
	var repr = '<{name}{props}>'.format({
		"name": name,
		"props": prop_str
	})
	
	return repr

# ====================================================== #
#                      BASE CLASSES                      #
# ====================================================== #
class ContentProperty extends EpubProperty:
	## Property that derives its value from the nodes content attribute.
	## Used in Epub 2.X format
	func _get_value():
		return self.node.attributes["content"]
	
	func _set_value(to):
		self.node.attributes["content"] = to
	
	static func from_nodes(root: XMLTree, node: XMLTree) -> ContentProperty:
		var prop: ContentProperty = ContentProperty.new(root)
		prop.node = node
		
		return prop

class TextProperty extends EpubProperty:
	## Property that derives its value from the nodes text.
	## Used in Epub 3.x format. See, [ContentProperty] for further the 2.x format.
	func _get_value():
		return self.node.text_content

	func _set_value(to):
		self.node.text_content = to 
	
	static func from_nodes(root: XMLTree, node: XMLTree) -> TextProperty:
		var prop: TextProperty = TextProperty.new(root)
		
		prop.node = node
		
		return prop
	
class DoubleProperty extends EpubProperty:
	## In scenarios where both the Epub 2.x & 3.x cannot be condensed into a 
	## single node, we'll need nodes for both versions
	var _node_2x: XMLTree
	var _node_3x: XMLTree
	var _default_value: Variant
	
	func _get_id():
		# Epub 2.x doesn't use id (Needs confirmation)
		return self._node_3x.attributes.get("id")

	func _set_id(to):
		if self.id != to:
			assert(not self.xml_root.id_exists(to))
			self._node_3x.attributes["id"] = to

	func _get_value():
		# Since we'll be making sure both the 2.x & 3.x nodes will have the same
		# value it doesn't matter which node we'll get from, using the 3.x node
		# because the .text syntax is preferable
		return self._node_3x.text_content
	
	func _set_value(to):
		if to == null:
			to = ""
		self._node_2x.attributes["content"] = to
		self._node_3x.text_content = to
	
	func resolve() -> void:
		var temp_val = self._node_3x.text_content
		if temp_val == null or (temp_val is String and temp_val.is_empty()):
			temp_val = self._node_2x.attributes.get_or_add("content", _default_value)
		if temp_val == null or (temp_val is String and temp_val.is_empty()):
			temp_val = _default_value
		assert(temp_val == null or temp_val is String)
		self.value = temp_val
	
	static func from_nodes(root: XMLTree, node_2x: XMLTree, node_3x: XMLTree, default_value: Variant = null) -> DoubleProperty:
		var prop: DoubleProperty = DoubleProperty.new(root)
		
		prop._node_2x = node_2x
		prop._node_3x = node_3x
		prop._default_value = default_value
		
		prop.resolve()
		
		return prop
	
class GroupProperty extends EpubProperty:
	## When a property has a cardinality of zero or more (creators, collections, etc..)
	
	var epub_properties: Array[EpubProperty] = []
	
	func _get_value():
		var props = epub_properties.duplicate()
		props.make_read_only()
		return props
	
	func _get(property: StringName) -> Variant:
		for epub_prop in self.epub_properties:
			if epub_prop.value == property:
				return epub_prop
		return
	
	func clear():
		for prop: EpubProperty in self.epub_properties.duplicate():
			prop.remove()
	
	func _to_string() -> String:
		return "<%s>\n  %s\n</%s>" % [self.name, "\n  ".join(self.epub_properties), self.name]

# ====================================================== #
#                      END OF FILE                       #
# ====================================================== #
