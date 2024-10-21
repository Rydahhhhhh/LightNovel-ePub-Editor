@tool
class_name EasyXml extends RefCounted

var root: XMLNode
var all_nodes: Array = []

func _init(xml: PackedByteArray) -> void:
	root = XML.parse_buffer(xml).root
	all_nodes = traverse(root)

func find(tag, attrs, kv_attrs, content):
	for node in all_nodes:
		if not node.name == tag:
			continue
		if not node.attributes.has_all(attrs + kv_attrs.keys()):
			continue
		if not kv_attrs.keys().all(func(k): return kv_attrs[k] == node.attributes[k]):
			continue
		if content != null and node.content != content:
			continue 
		return node
		
	return null

func findall(tag, attrs, kv_attrs, content):
	var matches = []
	
	for node in all_nodes:
		if not node.name == tag:
			continue
		if not node.attributes.has_all(attrs + kv_attrs.keys()):
			continue
		if not kv_attrs.keys().all(func(k): return kv_attrs[k] == node.attributes[k]):
			continue
		if content != null and node.content != content:
			continue 
		matches.append(node)
	
	return matches
	
static func traverse(from: XMLNode, depth: int = 0):
	var nodes = [from]
	for child in from.children:
		nodes.append_array(traverse(child))
	return nodes
