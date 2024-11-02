class_name TitleField extends EpubProperty.TextProperty

const name = "EpubTitle"

# Although the native behavior of subproperties gives this exact same
# functionality, this is the only way (that i'm aware of) that allows
# autocompletion
var sort_by: String:
	get():
		return self["sort_by_node"].value
	set(to):
		self["sort_by_node"].value = to

func _init(_root: XMLTree) -> void:
	super(_root)
	
	# EPUB 2.x
	# The first <dc:title> node should be considered the primary one.
	# <dc:title> is a mandatory node, so we make one if it wasn't found
	
	# Generally, if you have an epub file and there's no dc:title node
	# Something has gone VERY wrong, but we may as well fix it cause we can 
	# (if that comes up EVEN ONCE, I will fight the person who made that epub file)
	self.node = self.find_or_create("dc:title")
	
	# EPUB 3.x
	# The primary title is defined using the following logic:
	# 	1. it is the <dc:title> node whose title-type (refine) is main;
	# 	2. if there is no such refine, it is the first <dc:title> node.
	
	# Set an id if one doesn't already exist
	if self.id == null:
		self.id = "main-title"
	
	# MORE PARSING!!!!! I LOVE THAT ITS POSSIBLE FOR THINGS TO JUST BE... WRONG
	# WHAT IF EVERYTHING JUST WORKED ????????
	
	# it just works (tm)
	
	var title_type_node = self.find_or_create("meta", "main", {"property": "title-type"})
	title_type_node.attributes.get_or_add("refines")
	
	var title_type = self.add_subproperty("title-type", 
		TextProperty.from_nodes(
			self.xml_root,
			title_type_node
		).refines(self)
	)
	
	var refined_title_node = self.find("dc:title", null, {"id": title_type.refine_id})
	
	if refined_title_node == null:
		# This occurs when a meta nodes with title-type and main as text
		# does exists and has a refines property, but no nodes with the id it refines exist
		# As for how this could happen? See the rage comment above.
		
		# If that occurs then we'll ovverride 
		refined_title_node = self.node
		self.id = title_type.refine_id
	
	# Changing indexes isn't standard, it's relavent here for functionality
	# i.e that the *first* title elment should be used if nothing else matches
	self.node.index = 0
	assert(refined_title_node == self.node)
	assert(refined_title_node == self.find("dc:title"))
	
	self.add_subproperty("sort_by",
		DoubleProperty.from_nodes(
			self.xml_root,
			self.find_or_create("meta", null, {"name": "calibre:title_sort"}),
			self.find_or_create("meta", null, {"refines": self.id, "property": "file-as"}),
			self.value
		).refines(self)
	)
	
	return
