class_name OpfRoot extends OpfElement

signal tree_changed(changes)

var metadata: OpfGeneralElement

func _init(_node: XMLNode) -> void:
	super(_node)
	self.metadata = self.find("metadata")

# ====================================================== #
#                        METHODS                         #
# ====================================================== #
## Dumps this element to a [PackedByteArray].
## See [method XMLNode.dump_buffer] for further documentation.
func dump_buffer(
	pretty: bool = false, 
	indent_level: int = 0, 
	indent_length: int = 2
) -> PackedByteArray:
	return self.node.dump_buffer(pretty, indent_level, indent_length)

# ====================================================== #
#                      CONTRUCTORS                       #
# ====================================================== #
## Creates an [OpfRoot] instance from a buffer. [param opf_data] is a [PackedByteArray] containing 
## the raw data in XML format. 
static func from_buffer(opf_data: PackedByteArray) -> OpfRoot:
	return OpfRoot.new(XML.parse_buffer(opf_data).root)


func property(prop_cls):
	
	return 

# ====================================================== #
#                      END OF FILE                       #
# ====================================================== #
