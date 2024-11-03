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
			@warning_ignore("unsafe_property_access")
			nodes.append(self._node_2x)
			@warning_ignore("unsafe_property_access")
			nodes.append(self._node_3x)
		
		return nodes

var id: String: get = _get_id, set = _set_id
var refine_id: String: get = get_refine_id

func _init(_xml_root: XMLTree) -> void:
	self.xml_root = _xml_root
	self.xml_metadata = self.find("metadata")

func _get_id() -> String:
	return self.node.attributes.get("id")

func _set_id(to: String) -> void:
	if self.id != to:
		assert(not self.xml_root.id_exists(to))
		self.node.attributes["id"] = to

func get_refine_id() -> Variant:
	if not self.node.attributes.has("refines"):
		return null
	
	var _refine_id: String = self.node.attributes.get("refines")
	if _refine_id.begins_with("#"):
		return _refine_id.substr(1)
	return _refine_id

func refines(prop: EpubProperty) -> EpubProperty:
	
	for own_node: XMLTree in self._nodes:
		if own_node != null and own_node.attributes.has("refines"):
			own_node.bind_attribute("refines",  func() -> Variant:
				if prop.id == null:
					return null
				return "#" + prop.id
			)
	
	return self

## ====================================================== ##
##                        METHODS                         ##
## ====================================================== ##

## Removes it's [param node] and it's sub properties [param node's] from the tree
@warning_ignore("unused_parameter")
func remove(reason: String = "none") -> void:
	if self.group != null:
		self.group.epub_properties.erase(self)
	
	self.node.parent = null
	
	for prop: EpubProperty in self._sub_properties.values():
		prop.remove()
	
	#print("removed: '", str(node), "' Reason: ", reason)
	
	while self.get_reference_count():
		self.unreference()

func add_subproperty(name: String, prop: EpubProperty) -> Variant:
	if name in self._sub_properties:
		push_error("subproperty '%s' already exists")
		return
	
	self._sub_properties[name] = prop
	return prop


# ================== #
#   Search methods   #
# ================== #
func find_or_create(
	tag: String, 
	text_content: Variant = null, 
	kv_attrs: Dictionary = {},
	attrs: Array[String] = []
) -> XMLTree:
	var node_search_result := self.find(tag, text_content, kv_attrs, attrs)
	var requested_node: XMLTree
	if node_search_result == null:
		# Appeasing godot's UNSAFE_CALL_ARGUMENT
		var desired_text: String = "" if text_content == null else text_content
		requested_node = XMLTree.new(xml_metadata, tag, desired_text, kv_attrs)
	else:
		requested_node = node_search_result
	return requested_node

func find(
	tag: Variant, 
	text_content: Variant = null, 
	kv_attrs: Dictionary = {},
	attrs: Array[String] = []
) -> XMLTree:
	return self.xml_root.query_selector(XMLQuery.new(tag, text_content, kv_attrs, attrs))

func find_all(
	tag: Variant, 
	text_content: Variant = null, 
	kv_attrs: Dictionary = {},
	attrs: Array[String] = []
) -> Array[XMLTree]:
	return self.xml_root.query_selector_all(XMLQuery.new(tag, text_content, kv_attrs, attrs))

# ================== #
#   Private methods  #
# ================== #
func _get_value() -> Variant:
	return null

@warning_ignore("unused_parameter")
func _set_value(to: String) -> void:
	return

func _get(property: StringName) -> Variant:
	# If a inheriting class doesn't have a name, use a default
	if property == "name":
		if self.value == null:
			return "EpubPropertyEmpty"
		return "EpubProperty"
	
	if "_node" in property:
		var prop := property.substr(0, len(property) - 5)
		if prop in self._sub_properties:
			return self._sub_properties[prop]
	
	return

func _set(property: StringName, new_value: Variant) -> bool:
	if property in self._sub_properties:
		self._sub_properties[property].value = new_value
		return true
	return false

func _to_string() -> String:
	var prop_str := ' {key}="{value}"'.format({"key": "value", "value": self.value})
	for prop_key: String in self._sub_properties:
		var prop_value: Variant = self._sub_properties.get(prop_key).value
		
		if prop_value is String:
			@warning_ignore("unsafe_method_access")
			prop_value = prop_value.xml_escape(true)
		
		prop_str += ' {key}="{value}"'.format({"key": prop_key, "value": prop_value})
	
	@warning_ignore("unsafe_property_access")
	var repr := '<{name}{props}>'.format({
		"name": self.name,
		"props": prop_str
	})
	
	return repr

# ====================================================== #
#                      BASE CLASSES                      #
# ====================================================== #
class ContentProperty extends EpubProperty:
	## Property that derives its value from the nodes content attribute.
	## Used in Epub 2.X format
	func _get_value() -> String:
		return self.node.attributes["content"]
	
	func _set_value(to: Variant) -> void:
		self.node.attributes["content"] = to
	
	static func from_nodes(root: XMLTree, a_node: XMLTree) -> ContentProperty:
		var prop: ContentProperty = ContentProperty.new(root)
		prop.node = a_node
		
		return prop

class TextProperty extends EpubProperty:
	## Property that derives its value from the nodes text.
	## Used in Epub 3.x format. See, [ContentProperty] for further the 2.x format.
	func _get_value() -> String:
		return self.node.text_content

	func _set_value(to: String) -> void:
		self.node.text_content = to 
	
	static func from_nodes(root: XMLTree, a_node: XMLTree) -> TextProperty:
		var prop: TextProperty = TextProperty.new(root)
		
		prop.node = a_node
		
		return prop
	
class DoubleProperty extends EpubProperty:
	## In scenarios where both the Epub 2.x & 3.x cannot be condensed into a 
	## single node, we'll need nodes for both versions
	var _node_2x: XMLTree
	var _node_3x: XMLTree
	var _default_value: Variant
	
	func _get_id() -> String:
		# Epub 2.x doesn't use id (Needs confirmation)
		return self._node_3x.attributes.get("id")

	func _set_id(to: String) -> void:
		if self.id != to:
			assert(not self.xml_root.id_exists(to))
			self._node_3x.attributes["id"] = to

	func _get_value() -> String:
		# Because all nodes that *could* represent it's value will share the 
		# same value the node we get the value from doesn't matter, using the 
		# 3.x node because the .text_content syntax is preferable
		return self._node_3x.text_content
	
	func _set_value(to: String) -> void:
		self._node_2x.attributes["content"] = to
		self._node_3x.text_content = to
	
	func resolve() -> void:
		var temp_val := self._node_3x.text_content
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
	
	func _get_value() -> Array:
		var props := self.epub_properties.duplicate()
		props.make_read_only()
		return props
	
	func _get(property: StringName) -> Variant:
		for epub_prop in self.epub_properties:
			if epub_prop.value == property:
				return epub_prop
		return
	
	func clear() -> void:
		for prop: EpubProperty in self.epub_properties.duplicate():
			prop.remove()
	
	func _to_string() -> String:
		@warning_ignore("unsafe_property_access")
		return "<%s>\n  %s\n</%s>" % [self.name, "\n  ".join(self.epub_properties), self.name]

# ====================================================== #
#                      END OF FILE                       #
# ====================================================== #
