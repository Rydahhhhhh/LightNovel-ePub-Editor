class_name SeriesField extends EpubProperty.DoubleProperty
const name = "EpubSeries"

var index: String:
	get():
		return self["index_node"].value
	set(to):
		assert(str(to).is_valid_int())
		self["index_node"].value = str(to)
		

func _init(_root: XMLTree) -> void:
	super(_root)
	# EPUB 2.x
	# The string for its name is the value of the content attribute in the <meta> node whose 
	# name attribute has the value calibre:series.
	self._node_2x = self.find_or_create("meta", null, {"name": "calibre:series"})
	#self._node_2x.index = 4
	
	# EPUB 3.x
	# The object to use depends on the refine whose property has the value of collection-type:
	#	1. if it is series, use series;
	#	2. else use collection. 
	#
	# The string for its name is the value of the <meta> node whose property has the value of belongs-to-collection and which is refined.
	# The sortAs string used to sort the name is the value of the refine whose property has the value of file-as.
	# If there is no series, try to parse calibre:series as in the EPUB 2.x case.
	self._node_3x = self.find_or_create("meta", null, {"property": "belongs-to-collection"})
	if self.id == null:
		self.id = "collection-series"
	
	self.add_subproperty(
		"collection-type",
		TextProperty.from_nodes(
			self.xml_root,
			self.find_or_create("meta", "set", {"refines": self.id, "property": "collection-type"})
		).refines(self)
	)
	
	self.resolve()
	
	self.add_subproperty("index",
		DoubleProperty.from_nodes(
			self.xml_root,
			# EPUB 2.x
			# The position of the publication is the value of the content attribute – converted to a number – 
			# in the <meta> node whose name attribute has the value calibre:series_index.
			#
			# Please be aware that it can be a floating point number with up to two digits of precision 
			# e.g. 1.01, and zero and negative numbers are allowed.
			self.find_or_create("meta", null, {"name": "calibre:series_index"}),
			# EPUB 3.x
			# The position of the publication is the value of the refine whose property has the value of group-position.
			# If there is no series, try to parse calibre:series_index as in the EPUB 2.x case.
			self.find_or_create("meta", null, {"refines": self.id, "property": "group-position"}),
			"1.00"
		).refines(self)
	)
	return
