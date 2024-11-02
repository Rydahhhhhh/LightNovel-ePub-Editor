class_name Metadata extends EpubProperty

var title: TitleField
var creators: CreatorsField
var series: SeriesField
var description: DescriptionField
var language: LanguageField
var rights: RightsField
var pub_date: PubDateField
var mod_date: DateModifiedField
var publisher: PublisherField
var identifier: IdentifierField
var genres: GenresField

func _init(_root: XMLTree) -> void:
	super(_root)
	self.node = self.xml_metadata
	
	self.title = TitleField.new(self.xml_root)
	self.creators = CreatorsField.new(self.xml_root)
	self.series = SeriesField.new(self.xml_root)
	self.description = DescriptionField.new(self.xml_root)
	self.language = LanguageField.new(self.xml_root)
	self.rights = RightsField.new(self.xml_root)
	self.pub_date = PubDateField.new(self.xml_root)
	self.mod_date = DateModifiedField.new(self.xml_root)
	self.publisher = PublisherField.new(self.xml_root)
	self.identifier = IdentifierField.new(self.xml_root)
	self.genres = GenresField.new(self.xml_root)
	
	self.format()

func format():
	var core_element = []
	var refines = []
	var collection = []
	var calibre = []
	
	core_element.append(self.title.node)
	refines.append(self.title["title-type_node"].node)
	refines.append(self.title["sort_by_node"]._node_3x)
	
	calibre.append(self.title["sort_by_node"]._node_2x)
	
	for creator in self.creators.value:
		core_element.append(creator.node)
		refines.append(creator["role_node"].node)
		refines.append(creator["sort_by_node"].node)
	
	core_element.append(self.identifier.node)
	core_element.append(self.language.node)
	core_element.append(self.publisher.node)
	core_element.append(self.rights.node)
	core_element.append(self.pub_date.node)
	core_element.append(self.description.node)
	
	
	collection.append(self.series._node_3x)
	collection.append(self.series["collection-type_node"].node)
	collection.append(self.series["index_node"]._node_3x)
	
	calibre.append(self.series._node_2x)
	calibre.append(self.series["index_node"]._node_2x)
	
	var sigil = self.find("meta", null, {"name": "Sigil version"})
	if sigil:
		calibre.append(sigil)
	
	self.node.comments = []
	
	var i = 0
	
	self.node.add_comment("Core Bibliographic Metadata", i)

	for node in core_element:
		node.index = i
		i += 1
	
	self.node.add_comment(XMLTree.BLANK, i)
	self.node.add_comment("Subjects", i)
	for genre: GenreField in self.genres.value:
		genre.node.index = i
		i += 1
	
	self.node.add_comment(XMLTree.BLANK, i)
	self.node.add_comment("Refined Metadata for Title and Creators", i)
	
	for node in refines:
		node.index = i
		i += 1
	
	self.node.add_comment(XMLTree.BLANK, i)
	self.xml_metadata.add_comment("Modified Date", i)
	self.mod_date.node.index = i
	i += 1
	
	var cover = self.find("meta", null, {"name": "cover"})
	if cover:
		self.node.add_comment(XMLTree.BLANK, i)
		self.xml_metadata.add_comment("Cover Image", i)
		cover.index = i
		i += 1
	
	self.node.add_comment(XMLTree.BLANK, i)
	self.xml_metadata.add_comment("Series and Collection Metadata", i)
	
	for node in collection:
		node.index = i
		i += 1
	
	self.node.add_comment(XMLTree.BLANK, i)
	self.xml_metadata.add_comment("Calibre-specific Metadata", i)
	
	for node in calibre:
		node.index = i
		i += 1
	
	#self.node.add_comment(XMLTree.BLANK, i)
	#self.xml_metadata.add_comment("Unsorted", i)
	
	return
