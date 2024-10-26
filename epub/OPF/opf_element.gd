class_name OpfElement extends RefCounted
var children: Array[OpfGeneralElement]
var node: XMLNode
func _init(_node: XMLNode) -> void:
	self.node = _node
	self.children = self.node.children.map(OpfGeneralElement.new.bind(self))
# ====================================================== #
#                        METHODS                         #
# ====================================================== #
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
