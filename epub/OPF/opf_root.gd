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


# ====================================================== #
#                               IDK                    #
# ====================================================== #
func metadata_element(cls):
	return cls.new(self)

func primary_title():
	return PrimaryTitle.new(self)

class MetadataElement extends OpfGeneralElement:
	var element: OpfGeneralElement
	var element_2x
	var element_3x
	
	func _init(_root: OpfRoot) -> void:
		self.node = _root.node
		
		self.element_2x = epub_2x()
		self.element_3x = epub_3x()
		
		assert(self.validate_elements())
		self.configure()
		
		super(self.element.node, _root)
	
	func epub_2x():
		return null
	
	func epub_3x():
		return null
	
	func validate_elements():
		return false
	
	func configure() -> void:
		return
	
class PrimaryTitle extends MetadataElement:
	func epub_2x():
		# EPUB 2.X
		# The first <dc:title> element should be considered the primary one.
		# <dc:title> is a mandatory element, so we make one if it wasn't found
		
		# Generally, if you have an epub file and there's no dc:title element
		# Something has gone VERY wrong, but we may as well fix it cause we can 
		# (if that comes up EVEN ONCE, I will fight the person who made that epub file)
		var title_element = self.find_or_create("dc:title")
		
		# Epub 3x support
		# Ensuring we don't use an existing id
		if title_element.id == null and not self.id_exists("main-title"):
			title_element.id = "main-title"
		
		return title_element

	func epub_3x():
		# EPUB 3.X
		# The primary title is defined using the following logic:
		# 	1. it is the <dc:title> element whose title-type (refine) is main;
		# 	2. if there is no such refine, it is the first <dc:title> element.
		
		# MORE PARSING, I LOVE THAT ITS POSSIBLE FOR THINGS TO JUST BE... WRONG
		# WHAT IF EVERYTHING JUST WORKED ????????
		var title_type_element = self.find_or_create("meta", [], {"property": "title-type"}, "main")
		var refine_id = title_type_element.attrs.get_or_add("refines", self.element_2x.id)
		
		if refine_id.begins_with("#"):
			refine_id = refine_id.substr(1)
		
		return self.find("dc:title", [], {"id": refine_id})
	
	func validate_elements():
		return self.epub_2x() == self.epub_3x()

	func configure() -> void:
		# Both element_2x and element_3x are the same (see validate_elements method)
		self.element = self.epub_2x()
		# Ensure 
		self.element.index = 0
		return

class Description extends MetadataElement:
	func epub_2x():
		return self.find_or_create("dc:description")

class Language extends MetadataElement:
	func epub_2x():
		return self.find_or_create("dc:language")

class PubDate extends MetadataElement:
	func epub_2x():
		for element in self.findall("dc:date"):
			if element.attrs.get("opf:event") == null:
				return element
		return

class Genres extends MetadataElement:
	func epub_2x():
		return self.findall("dc:subject")

class Series extends MetadataElement:
	func epub_2x():
		return self.find("meta", [], {"name": "calibre:series"})
	
	func epub_3x():
		return self.find("meta", [], {"property": "belongs-to-collection"})
	
	#func index_element():
		#if self.epub_version == 3:
			#return self.find("meta", [], {"refines": self.element_id, "property": "group-position"})
		#return self.find("meta", [], {"name": "calibre:series_index"})
#
	#func sort_element():
		#if self.epub_version == 3:
			#return self.find("meta", [], {"refines": self.element_id, "property": "file-as"})
		#return null
#
	#func identifier():
		#if self.epub_version == 3:
			#return self.find("meta", [], {"refines": self.element_id, "property": "dcterms:identifier"})
		#return null


# ====================================================== #
#                      END OF FILE                       #
# ====================================================== #
