class_name OpfElement extends RefCounted
var children: Array[OpfGeneralElement]
var node: XMLNode
func _init(_node: XMLNode) -> void:
	self.node = _node
	self.children = self.node.children.map(OpfGeneralElement.new.bind(self))
# ====================================================== #
#                        METHODS                         #
# ====================================================== #
## Returns the first [OpfElement] that matches the provided parameters.
## [br][br]
## [param tag]: The expected tag name to match.[br]
## [param attrs]: An array of attribute names that must be present (default is an empty array).[br]
## [param kv_attrs]: A dictionary of key-value pairs to match against attributes (default is an empty dictionary).[br]
## [param text]: The expected text content to match (default is [code]null[/code]).[br]
## [br]
## Returns the first matching [OpfElement] or [code]null[/code] if no match is found. See 
## [method test_properties] for further documentation.
func find(
	tag, 
	attrs: Array[String] = [], 
	kv_attrs: Dictionary = {}, 
	text = null
) -> OpfGeneralElement:
	for element: OpfElement in self.all_elements:
		if element.test_properties(tag, attrs, kv_attrs, text):
			return element
	return null

## Returns the an [Array] of [OpfElement] that matches the provided parameters.
## See [method find] for documentation.
func findall(
	tag, 
	attrs: Array[String] = [], 
	kv_attrs: Dictionary = {}, 
	text = null
) -> Array[OpfElement]:
	return self.all_elements.filter(func(e: OpfElement): return e.test_properties(tag, attrs, kv_attrs, text))

func create_child(
	tag: String, 
	attrs: Dictionary = {}, 
	text: String = ""
) -> OpfElement:
	var elem = OpfElement.new(XMLNode.new())
	elem.tag = tag
	elem.attrs = attrs
	elem.text = text
	
	self.add_child(elem)
	
	return elem

func add_child(element: OpfElement) -> OpfElement:
	self.children.append(element)
	self.node.children.append(element.node)
	return element

## Tests the properties of the current object against the specified criteria.
## [br][br]
## [param tag] is the expected tag name. Set [param tag] to [code]null[/code] if you wish not to test for tag.[br]
## [param attrs] is an array of required attribute names.[br]
## [param kv_attrs] is a dictionary of key-value pairs to match against attributes.[br]
## [param text] is the expected text content. Set [param text] to [code]null[/code] if you wish not to estfor text.[br]
## [br]
## [b]Note:[/b] [param tag] and [param text] are [b]not[/b] typed because typed variables aren't nullable.[br]
## [b]Written on stable version 4.3 this behavior may change in the future. [/b]
func test_properties(tag, attrs: Array[String], kv_attrs: Dictionary, text):
	# If tag or text is provided as "" (empty) then it should match as such
	# so as to have a way to not match entirely it'll need to be 
	# untyped so it can be null
	
	if tag != null and not self.tag == tag:
		return false
	if not self.attrs.has_all(attrs + kv_attrs.keys()):
		return false
	if not kv_attrs.keys().all(func(k): return kv_attrs[k] == self.attributes[k]):
		return false
	if text != null and self.text != text:
		return false 
	return true
## Traverses the element tree starting from itself. [param depth] is the maximum depth to traverse. 
## If [param depth] is -1, the entire tree will be traversed. A [param depth] of 0 will return only 
## the initial element, while a [param depth] of 1 will include the initial element and its 
## immediate children. Higher depths continue to include each subsequent level of descendants 
## (e.g., [param depth=2] includes the initial element, its children, and its children's children).
func traverse(depth: int = 1) -> Array[OpfElement]:
	assert(depth >= -1)
	
	var elements: Array[OpfElement] = [self]
	if depth != 0:
		var new_depth = -1 if depth == -1 else depth - 1
		for child: OpfElement in self.children:
			elements.append_array(child.traverse_tree(depth - 1))
	return elements


# ====================================================== #
#                      END OF FILE                       #
# ====================================================== #
