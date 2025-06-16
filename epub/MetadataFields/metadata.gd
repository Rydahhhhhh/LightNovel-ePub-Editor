class_name Metadata extends RefCounted

# see https://www.w3.org/TR/epub-33

const ELEMENT_CLASSES_BY_TAG := {
	"dc:title": _Title,
	"meta": _Meta
}

var xml_metadata: XMLTree

var issues: Array[Issue]

func _init(root: XMLTree) -> void:
	# Locates the metadata element
	self.xml_metadata = root.query_selector(XMLQuery.new("metadata"))
	
	var elements_by_tag = {}
	var elements_by_id := {}
	
	# Iterates through it's children
	for xml_element: XMLTree in self.xml_metadata.children:
		var tag = xml_element.tag
		if tag not in ELEMENT_CLASSES_BY_TAG:
			continue
		
		var elem_wrapper = ELEMENT_CLASSES_BY_TAG[tag].new(xml_element)
		elem_wrapper.IssueDetected.connect(self.create_issue)
		
		if "raw_id" in elem_wrapper and elem_wrapper.raw_id != null:
			elements_by_id[elem_wrapper.raw_id] = elem_wrapper
		
		elements_by_tag.get_or_add(tag, []).append(elem_wrapper)
	
	for tag_wrapper in elements_by_tag["meta"]:
		if tag_wrapper.raw_refines in elements_by_id:
			elements_by_id[tag_wrapper.raw_refines].attach_refine(tag_wrapper)
	
	# Epub files have both 2.x and 3.x versions that follow different guidelines
	# We'll prioritise 3.x but we can also do both if possible
	
	### Title parsing
	var title_wrappers: Array = elements_by_tag["dc:title"]
	
	# A <dc:title> node could represent any of the following:
	# 'main', 'subtitle', 'short', 'collection', 'edition' and 'expanded'
	# main is the primary title so we should deal with the others first
	
	var collection_wrappers = []
	
	for title_wrapper: _Title in title_wrappers:
		if title_wrapper.title_type != null:
			# Support for anything other than 'main' and 'collection' is rare
			# While I could combine the other title types into the main one
			# I'll be editing the main one anyway so it'll make no difference
			var title_type = title_wrapper.title_type.element.text_content
			
			if title_type != "main":
				title_wrappers.erase(title_wrapper)
				if title_type == "collection":
					collection_wrappers.append(title_wrapper)
				else:
					title_wrapper.element.parent = null
		 	
	# EPUB 2.x
	# The first <dc:title> node should be considered the primary one.
	# <dc:title> is a mandatory node, so we make one if it wasn't found
	
	# EPUB 3.x
	# The primary title is defined using the following logic:
	# 	1. it is the <dc:title> node with an id refined by a <meta> node 
	#      with 'property: title-type' and a value of 'main'
	# 	2. if no nodes meet the above then, it is the first <dc:title> node.
	
	match len(title_wrappers):
		0: # No nodes exist
			# Make one
			var xml_title = XMLTree.new(self.xml_metadata, "dc:title")
			var title_node := _Title.new(xml_title)
			title_node.make_main()
			
			self.create_issue(
				Issue.new(
					Issue.Severity.WARNING,
					Issue.Status.IGNORED,
					"No titles found in metadata"
				)
			)
			
		1: # One nodes exist
			# it'll always be the main title following the above schema
			var title_node: _Title = title_wrappers[0]
			title_node.make_main()
		_: # more than 1 nodes exists
			# Gets the title nodes which are refined with main
			var main_titles = title_wrappers.filter(func(e): return e.is_main())
			match len(main_titles):
				0: 
					# It's the first title node
					var title_node: _Title = title_wrappers[0]
					title_node.make_main()
				1: # It's the refined title node
					var title_node: _Title = main_titles[0]
					title_node.make_main()
				_: # Raise an issue to be solved later
					self.create_issue(
						Issue.new(
							Issue.Severity.WARNING,
							Issue.Status.RESOLTUION_REQUIRED,
							"Multiple refined title nodes with 'title-type: main'",
							Issue.Handler.new(
								func(choice):
									for t in main_titles:
										if t.element.text_content == choice:
											t.make_main()
									return,
								main_titles.map(func(e: _Title): return e.element.text_content)
							)
						)
					)
	
	print(self.xml_metadata.dump_str(true))
	return 

func issue_resolved(handler: Issue.Handler):
	print("resolved")
	return

func create_issue(issue: Issue):
	if not issue.handler.is_empty:
		# This is a wrapper function
		var old_handler_fn = issue.handler.handler_fn
		
		issue.handler.handler_fn = func(arg):
			old_handler_fn.call(arg)
			issue_resolved(issue.handler)
			return 
		pass
	self.issues.append(issue)
	return

class _Element extends RefCounted:
	signal IssueDetected(issue: Issue)
	
	var element: XMLTree;
	
	func _init(_element: XMLTree) -> void:
		self.element = _element
		return
	
	func _get(property: StringName) -> Variant:
		if property in self.attributes:
			return self.element.attributes.get(property, null)
		return
	
	func _set(property: StringName, value: Variant) -> bool:
		if property in self.attributes:
			return self.element.attributes.set(property, value)
		return false
	
	func _to_string() -> String:
		return str(self.element)
	
	static func unprefix(str: String, prefix):
		return str.substr(len(prefix)) if str.begins_with(prefix) else str 
	
class _Title extends _Element:
	const attributes = ["dir", "id", "xml:lang"]
	
	var title_type: _Meta;
	var display_seq;
	var file_as;
	
	var raw_id:
		get:
			if "id" in self:
				return unprefix(self.id, "#")
			return null
	
	func attach_refine(_meta: _Meta):
		match _meta.property:
			"title-type":
				if self.title_type != null:
					if self.title_type.element.text_content == _meta.element.text_content:
						
						self.IssueDetected.emit(Issue.Info("dc:title has a duplicate refine element,"))
						return
					
					self.IssueDetected.emit(Issue.new(
						Issue.Severity.WARNING,
						Issue.Status.UNRESOLVED,
						"dc:title refined with 'title-type' more than once",
						Issue.Handler.new(
							func(x): return x,
							[],
							""
						)
					))
					
					return
					
				var valid_title_types = ["main", "subtitle", "short", "collection", "edition", "expanded"]
				if _meta.element.text_content not in valid_title_types:
					self.IssueDetected.emit(
						Issue.new(
							Issue.Severity.INFO,
							Issue.Status.RESOLVED,
							"'title-type' element with value '%s' may not be supported" % _meta.element.text_content
						)
					)
					
				self.title_type = _meta
			"display-seq":
				pass
			"file-as":
				pass
			_:
				self.IssueDetected.emit(Issue.new(
					Issue.Severity.ERROR,
					Issue.Status.UNRESOLVED,
					"Unknown property '%s'" % _meta.property
				))
		return
	
	func make_main():
		if self.element.id_exists("main-title"):
			push_error("id exists")
			return
		
		self.id = "main-title"
		
		if self.title_type == null:
			# I dont need to set the refines attribute here because it gets binded anyway
			# Future me please don't hate me! :)
			var xml_meta_elem = XMLTree.new(self.element.parent, "meta", "main", {"property": "title-type"})
			self.title_type = _Meta.new(xml_meta_elem)
		
		self.title_type.element.bind_attribute("refines", func(): return "#"+self.raw_id)
		self.title_type.element.index = self.element.index + 1
		
		return
	
	func is_main():
		if self.title_type == null:
			return false
		return self.title_type.element.text_content == "main"

class _Meta extends _Element:
	const attributes = ["dir", "id", "property", "refines", "scheme", "xml:lang"]
	
	var raw_refines:
		get:
			if "refines" in self:
				return unprefix(self.refines, "#")
			return null
	
	func _init(_element: XMLTree) -> void:
		super(_element)
		if "property" not in self:
			## FUCK YOU CALBIBRE & SIGIL
			# TODO
			#push_error("property attribute is required on elements: 'meta'")
			pass
		
		return
	
	
