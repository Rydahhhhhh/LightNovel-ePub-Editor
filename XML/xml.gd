class_name Xml

## Fork of https://github.com/elenakrittik/GodotXML 

## Parses file content as XML into a [XMLDocument].
## The file at the specified [code]path[/code] [b]must[/b] be readable.
## File content [b]must[/b] be a syntactically valid XML document.
static func parse_file(path: String) -> XMLTree:
	var file := FileAccess.open(path, FileAccess.READ)
	var xml: PackedByteArray = file.get_as_text().to_utf8_buffer()
	file = null
	
	return Xml._parse(xml)

## Parses string as XML into a [XMLDocument].
## String content [b]must[/b] be a syntactically valid XML document.
static func parse_str(xml: String) -> XMLTree:
	return Xml._parse(xml.to_utf8_buffer())

## Parses byte buffer as XML into a [XMLDocument].
## Buffer content [b]must[/b] be a syntactically valid XML document.
static func parse_buffer(xml: PackedByteArray) -> XMLTree:
	return Xml._parse(xml)

static func _parse(xml: PackedByteArray) -> XMLTree:
	xml = XMLUtils.cleanup_double_blankets(xml)  # see comment in function body

	var queue: Array[XMLTree] = []  # queue of unclosed tags

	var parser := XMLParser.new()
	parser.open_buffer(xml)
	
	var root: XMLTree
	
	while parser.read() != ERR_FILE_EOF:
		var node: XMLTree = _make_node(queue, parser)

		# if node type is NODE_TEXT, there will be no node, so we just skip
		if node == null:
			continue
		
		# if we just started, we set our first node as root and initialize queue
		if len(queue) == 0:
			root = node
			root.root = root
			queue.append(node)
		else:
			var node_type := parser.get_node_type()
			
			node.root = root
			# below, `queue.back().children.append(...)` means:
			# - take the last node
			# - since we are inside that unclosed node, all non-closing nodes we get are it's children
			# - therefore, we access .children and append our non-closing node to them

			# hopefully speaks for itself
			if node.standalone:
				# parent setter
				node.parent = queue.back()

			# same here
			elif node_type == XMLParser.NODE_ELEMENT_END:
				var last: XMLTree = queue.pop_back()  # get-remove last unclosed node

				# if we got a closing node, but it's name is not the same as opening one, it's an error
				if node.tag != last.tag:
					push_error(
						"Invalid closing tag: started with %s but ended with %s. Ignoring (output may be incorrect)." % [last.tag, node.tag]
					)
					# instead of break'ing here we just continue, since often invalid name is just a typo
					continue

				# we just closed a node, so if the queue is empty we stop parsing (effectively ignoring
				# anything past the first root). this is done to prevent latter roots overwriting former
				# ones in case when there's more than one root (invalid per standard, but still used in
				# some documents). we do not natively support multiple roots (and will not, please do not
				# open PRs for that), but if the user really needs to, it is trivial to wrap the input with
				# another "housing" node.
				if queue.is_empty():
					break

			# opening node
			else:
				node.parent = queue.back()
				queue.append(node)  # move into our node's body

	# if parsing ended, but there are still unclosed nodes, we report it
	if not queue.is_empty():
		queue.reverse()
		var names: Array[String] = []

		for node in queue:
			names.append(node.tag)

		push_error("The following nodes were not closed: %s" % ", ".join(names))
	
	return root

static func _make_node(queue: Array[XMLTree], parser: XMLParser) -> Variant:
	var node_type := parser.get_node_type()
	
	match node_type:
		XMLParser.NODE_ELEMENT:
			var node := XMLTree.new()
			
			node.tag = parser.get_node_name()
			node.standalone = parser.is_empty()  # see .is_empty() docs
			
			var attr_count: int = parser.get_attribute_count()
			
			for attr_idx in range(attr_count):
				node.attributes[parser.get_attribute_name(attr_idx)] = parser.get_attribute_value(attr_idx)
			
			return node
		XMLParser.NODE_ELEMENT_END:
			var node := XMLTree.new()
			
			node.tag = parser.get_node_name()
			node.standalone = false  # standalone nodes are always NODE_ELEMENT
			
			return node
		XMLParser.NODE_TEXT:
			# ignores blank text before root node; it is easier this way, trust me
			if queue.is_empty():
				return
				
			# XMLParser treats blank stuff between nodes as NODE_TEXT, which is unwanted
			# we therefore strip "blankets", resulting in only actual content slipping into .content
			queue.back().text_content += parser.get_node_data().strip_edges()
			
			return
			
		XMLParser.NODE_COMMENT:
			var last_node: XMLTree = queue.back()
			last_node.add_comment(parser.get_node_name().strip_edges())
			
			return 
		XMLParser.NODE_CDATA:
			if queue.is_empty():
				return
			var last_node: XMLTree = queue.back()
			last_node.cdata.append(parser.get_node_name().strip_edges())
			return
	return
