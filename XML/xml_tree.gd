@tool
class_name XMLTree extends RefCounted

const BLANK = "_BLANK_"

var _bindings: Dictionary = {}

var root: XMLTree

var tag: StringName
var text_content: String = ""
var _attributes: Dictionary = {}
var attributes: Dictionary = {}: get = _get_attributes
var children: Array[XMLTree] = []
var standalone: bool
var cdata = []
var comments: Array[Array] = []

var parent: XMLTree:
	set(to):
		if self.parent != null:
			self.parent.children.remove_at(self.index)
		parent = to
		
		if parent != null and self not in parent.children:
			parent.children.append(self)

var index: int:
	get():
		if self.is_root():
			return 0
		if parent == null:
			push_error("no parent and node isn't root")
		
		return self.parent.children.find(self)
	set(to):
		if self.is_root():
			push_warning("cannot set index on root")
			return
		if parent == null:
			push_error("no parent and node isn't root")
		
		self.parent.children.remove_at(self.index)
		self.parent.children.insert(to, self)

func _init(_parent: XMLTree = null, _tag: String = "", _text_cotent := "", _attributes := {}) -> void:
	self.tag = _tag
	self.text_content = _text_cotent
	
	if _attributes.has("refines") and not _attributes["refines"].begins_with("#"):
		_attributes["refines"] = "#" + _attributes["refines"]
	
	self.attributes = _attributes
	
	if _parent != null:
		self.parent = _parent
		self.root = self.parent.root
	
	return

## ====================================================== ##
##                        METHODS                         ##
## ====================================================== ##

## Binds the value of a given attribute to callable
func bind_attribute(attribute: String, fn: Callable):
	self._bindings[attribute] = fn

func _get_attributes():
	for binded_attribute in self._bindings:
		var fn = self._bindings[binded_attribute]
		attributes[binded_attribute] = fn.call()
	
	return attributes

func add_comment(what: String, index: int = -1):
	if index == -1:
		index = len(self.comments)
	assert(index > -1)
	if index >= len(self.comments):
		self.comments.resize(index + 1)
	
	self.comments[index].append(what)
	return

# ================== #
#   Search methods   #
# ================== #
func get_element_by_id(id: String) -> XMLTree:
	return self.query_selector(XMLQuery.kv_only({"id": id}))

func get_elements_by_tag_name(tagName: String) -> Array[XMLTree]:
	return self.query_selector_all(XMLQuery.new(tagName))

## Returns the first [XMLTree] that matches the provided [XMLQuery].
## Returns [code]null[/code] if no match is found.  
## See [method test_properties] for further documentation.
func query_selector(query: XMLQuery) -> XMLTree:
	for node: XMLTree in self.get_descendants():
		if query.test(node):
			return node
	return

func query_selector_all(query: XMLQuery) -> Array[XMLTree]:
	var nodes: Array[XMLTree] = []
	for node: XMLTree in self.get_descendants():
		if query.test(node):
			nodes.append(node)
	return nodes

# ================== #
#    Util methods    #
# ================== #
func get_descendants(include_self := true) -> Array[XMLTree]:
	var nodes: Array[XMLTree] = []
	
	if include_self:
		nodes.append(self)
	
	for child in children:
		nodes.append_array(child.get_descendants())
	
	return nodes

func id_exists(id: String) -> bool:
	return self.root.get_element_by_id(id) != null

func generate_id():
	var node_name: String = self.tag
	
	if node_name.contains(":"):
		node_name = node_name.split(":")[-1]
	
	var i = 1
	var valid_id = node_name + str(i)
	
	while self.id_exists(valid_id):
		i += 1
		valid_id = node_name + str(i)
		assert(i < 1000)
	return valid_id

func is_root() -> bool:
	return self.root == self

# ================== #
#      Overrides     #
# ================== #
func _to_string() -> String:
	return self.dump_str(true)

## ====================================================== ##
## Everything below this is from https://github.com/elenakrittik/GodotXML 
## albeit with all the classes change to XMLTree
## ====================================================== ##


## Dumps this node to the specified file.
## The file at the specified [code]path[/code] [b]must[/b] be writeable.
## See [method XMLTree.dump_str] for further documentation.
func dump_file(
	path: String,
	pretty: bool = false,
	indent_level: int = 0,
	indent_length: int = 2,
) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	var xml: String = self.dump_str(pretty, indent_level, indent_length)
	file.store_string(xml)
	file = null

## Dumps this node to a [PackedByteArray].
## See [method XMLTree.dump_str] for further documentation.
func dump_buffer(
	pretty: bool = false,
	indent_level: int = 0,
	indent_length: int = 2,
) -> PackedByteArray:
	return self.dump_str(pretty, indent_level, indent_length).to_utf8_buffer()

## Dumps this node to a [String].
## Set [param pretty] to [code]true[/code] if you want indented output.
## If [param pretty] is [code]true[/code], [param indent_level] controls the initial indentation level.
## If [param pretty] is [code]true[/code], [param indent_length] controls the length of a single indentation level.
func dump_str(
	pretty: bool = false,
	indent_level: int = 0,
	indent_length: int = 2,
) -> String:
	if indent_level < 0:
		push_warning("indent_level must be >= 0")
		indent_level = 0

	if indent_length < 0:
		push_warning("indent_length must be >= 0")
		indent_length = 0
	return self._dump() if not pretty else self._dump_pretty(indent_level, indent_length)

func _dump() -> String:
	var attribute_string := ""
	var children_string := ""
	var cdata_string = ""

	if not self.attributes.is_empty():
		attribute_string += " "
	
		for attribute_key in self.attributes:
			var attribute_value = self.attributes.get(attribute_key)

			if attribute_value is String:
				attribute_value = attribute_value.xml_escape(true)

			attribute_string += '{key}="{value}"'.format({"key": attribute_key, "value": attribute_value})

	for child: XMLTree in self.children:
		children_string += child._dump()

	for cdata_content in self.cdata:
		cdata_string += "<![CDATA[%s]]>" % cdata_content.replace("]]>", "]]]]><![CDATA[>")

	if self.standalone:
		return "<" + self.name + attribute_string + "/>"
	else:
		return (
			"<" + self.name + attribute_string + ">" +
			self.content.xml_escape() + cdata_string + children_string +
			"</" + self.name + ">"
		)

func _dump_pretty(indent_level: int, indent_length: int) -> String:
	var indent_string := " ".repeat(indent_level * indent_length)
	var indent_next_string := " ".repeat((indent_level + 1) * indent_length)
	var attribute_string := ""
	var content_string = self.text_content.xml_escape() if not self.text_content.is_empty() else ""
	var children_string := ""
	var cdata_string := ""

	if not self.attributes.is_empty():
		var attribute_keys = self.attributes.keys()
		attribute_keys.sort()
		
		# This functionality is for epub opf files, 
		# while the xmltree should function independant from parsing opf
		# TODO Put this implementation in the epub property somehow
		if "refines" in attribute_keys:
			attribute_keys.erase("refines")
			attribute_keys.push_front("refines")
		
		for attribute_key in attribute_keys:
			var attribute_value = self.attributes.get(attribute_key)

			if attribute_value is String:
				attribute_value = attribute_value.xml_escape(true)

			attribute_string += ' {key}="{value}"'.format({"key": attribute_key, "value": attribute_value})
	
	var comment_strings = self.comments.duplicate()
	for child: XMLTree in self.children:
		if not comment_strings.is_empty():
			var comment_string_arr = comment_strings.pop_front()
			for comment_string in comment_string_arr:
				if comment_string != "":
					if comment_string == self.BLANK:
						children_string += "\n" + indent_next_string
					else:
						children_string += "\n" + indent_next_string + "<!-- %s -->" % comment_string
		children_string += "\n" + child.dump_str(true, indent_level + 1, indent_length)
	
		if child == self.children[-1]:
			while not comment_strings.is_empty():
				var comment_string_arr = comment_strings.pop_front()
				for comment_string in comment_string_arr:
					if comment_string != "":
						if comment_string == self.BLANK:
							children_string += "\n" + indent_next_string
						else:
							children_string += "\n" + indent_next_string + "<!-- %s -->" % comment_string
				
			children_string += "\n" + indent_string
	
	if self.standalone:
		return indent_string + "<" + self.tag + attribute_string + "/>"
	else:
		return ( 
			indent_string + "<" + self.tag + attribute_string + ">" +
			content_string + children_string + 
			 "</" + self.tag + ">"
		)

# ====================================================== #
#                      END OF FILE                       #
# ====================================================== #
