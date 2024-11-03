class_name XMLQuery extends Object

var tag: Variant
var text_content: Variant
var attrs : Array[String] = []
var kv_attrs: Dictionary = {}

var _match_tag: bool: 
	get():
		return self.tag != null

var _match_text: bool: 
	get():
		return self.text_content != null

## [b]Note:[/b] [param tag] and [param text] are [b]not[/b] typed because typed variables aren't nullable.[br]
## [b]Written on stable version 4.3 this behavior may change in the future. [/b]
func _init(
	_tag: Variant, 
	_text_content: Variant = null, 
	_kv_attrs: Dictionary = {},
	_attrs: Array[String] = []
) -> void:
	
	if _tag != null:
		assert(_tag is String)
	
	if _text_content != null:
		assert(_text_content is String)
	
	if _tag != null:
		self.tag = _tag
	
	self.text_content = _text_content
	
	self.attrs = _attrs
	self.kv_attrs = _kv_attrs
	return

## Tests the properties of [param node] object against the specified criteria.
func test(node: XMLTree) -> bool:
	if self._match_tag and self.tag != node.tag:
		return false
	
	if self._match_text and self.text_content != node.text_content:
		return false 
	
	if not node.attributes.has_all(self.attrs + self.kv_attrs.keys()):
		return false
	
	var match_attrs: Callable = func(k: String) -> bool: 
		var v1: String = kv_attrs[k]
		var v2: String = node.attributes[k]
		
	
		# This functionality is for epub opf files, 
		# while the xmlquery should function independant from parsing opf
		# TODO Put this implementation in the epub property somehow
		# I'm not sure why there's an optional '#' prefix for id/refines in Epub 3.0 
		# but it exists and it annoys me
		if k in ["refines", "id"]:
			if v1.begins_with("#"):
				v1 = v1.substr(1)
			if v2.begins_with("#"):
				v2 = v2.substr(1)
		
		return v1 == v2
	
	if not kv_attrs.keys().all(match_attrs):
		return false
	
	return true

static func kv_only(_kv_attrs: Dictionary) -> XMLQuery:
	return XMLQuery.new(null, null, _kv_attrs)
