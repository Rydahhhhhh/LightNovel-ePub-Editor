class_name OpfElement extends RefCounted
var children: Array[OpfGeneralElement]
var node: XMLNode
func _init(_node: XMLNode) -> void:
	self.node = _node
	self.children = self.node.children.map(OpfGeneralElement.new.bind(self))
# ====================================================== #
#                        METHODS                         #
# ====================================================== #
# ====================================================== #
#                      END OF FILE                       #
# ====================================================== #
