@tool
extends Node

enum PubStatus {ONGOING, COMPLETED, HIATUS, STALLED, CANCELLED, UNKNOWN}

const BASE_URL := "https://ranobedb.org/api/v0"
const CACHE_PATH = "user://RanobeDB.dat"

const Sort = ['Relevance', 'Title', 'Release date']
const SortOrder = ['asc', 'desc']
const Logic = ['and', 'or`']
const ReleaseFormats = ['digital', 'print', 'audio']
const Languages = ['ja', 'en', 'zh-Hans', 'zh-Hant', 'fr', 'es', 'ko', 'ar', 'bg', 'ca', 'cs', 'ck', 'da', 'de', 'el', 'eo', 'eu', 'fa', 'fi', 'ga', 'gd', 'he', 'hi', 'hr', 'hu', 'id', 'it', 'iu', 'mk', 'ms', 'la', 'lt', 'lv', 'nl', 'no', 'pl', 'pt-pt', 'pt-br', 'ro', 'ru', 'sk', 'sl', 'sr', 'sv', 'ta', 'th', 'tr', 'uk', 'ur', 'vi']

var cache: Dictionary:
	get():
		if cache.get("Loaded", false):
			return cache
		if not FileAccess.file_exists(CACHE_PATH):
			FileAccess.open(CACHE_PATH, FileAccess.WRITE).store_var({}, true)
			
		cache = FileAccess.open(CACHE_PATH, FileAccess.READ).get_var(true)
		cache.Loaded = true
		return cache

func update_cache() -> void:
	var _cache = cache
	_cache.erase("Loaded")
	
	FileAccess.open(CACHE_PATH, FileAccess.WRITE).store_var(_cache, true)
	
	cache.Loaded = false
	print(cache)
	return

func request(endpoint: String) -> Dictionary:
	var url = "%s/%s" % [BASE_URL, endpoint]
	
	print("Requesting %s..." % url)
	
	#print_debug("Requesting %s..." % url)
	
	return (await Api.fetch(url))

func validate_cache(query):
	var cached_data = cache.get_or_add(query, {})
	
	var last_update = cached_data.get("last_update", null)
	var data = cached_data.get("data", null)
	
	var use_cache = true
	if null in [last_update, data]:
		use_cache = false
	else:
		var time_since_update = Time.get_unix_time_from_system() - last_update
		var days_since_update = Time.get_date_dict_from_unix_time(time_since_update).day - 1
		if days_since_update > 7:
			use_cache = false
	
	return use_cache

#func fetch_character_detail(id: int, use_cache: bool = true):
	#var character_details: Dictionary = cache.get_or_add("character detail", {})
	#var character_detail_cache: YattaCache = character_details.get_or_add(id, YattaCache.new())
	#
	#if not use_cache or character_detail_cache.invalid:
		#var data = (await request("avatar/%s" % id)).data
		#character_detail_cache.data = SrCharacterDetail.new(data)
		#update_cache()
	#else:
		#print("Using cache for 'fetch_character_detail'")
	#
	#ResourceSaver.save(character_detail_cache.data, 'lingsha.tres')
	#
	#return character_detail_cache.data

func fetch_book(
	query: String, 
	page: int = 1,
	limit: int = 24, 
	release_languages: Array[String] = [], 
	release_language_logic := 'and', 
	release_formats: Array[String] = [],
	release_format_logic := 'and',
	staff_ids: Array[int] = [],
	staff_logic := 'and',
	publisher_ids: Array[int] = [],
	publisher_logic := 'and',
	sort := 'Relevance',
	sort_order := 'desc'
):
	query = "books?q=%s" % query
	
	var parameters = ["page=%s" % page, "limit=%s" % limit]
	
	for rl in release_languages:
		if rl in Languages:
			parameters.append("rl=%s" % rl)
	if release_languages and release_language_logic in Logic:
		parameters.append("rll=%s" % release_language_logic)
	
	for rl in release_formats:
		if rl in ReleaseFormats:
			parameters.append("rl=%s" % rl)
	if release_formats and release_format_logic in Logic:
		parameters.append("rfl=%s" % release_format_logic)
	
	for staff_id in staff_ids:
		parameters.append("staff=%s" % staff_id)
	if staff_ids and staff_logic in Logic:
		parameters.append("sl=%s" % staff_logic)
	
	for publisher_id in publisher_ids:
		parameters.append("p=%s" % publisher_id)
	if publisher_ids and publisher_logic in Logic:
		parameters.append("pl=%s" % publisher_logic)
	
	if sort in Sort and sort_order in SortOrder:
		parameters.append("sort=%s %s" % [sort, sort_order])
	
	query = query + "&" + "&".join(parameters)
	query = query.replace(" ", "+")
	
	var book_query: Dictionary = cache.get_or_add("book", {})
	var book_query_cache: RanobeCache = book_query.get_or_add(query, RanobeCache.new())
	
	if book_query_cache.invalid:
		var data = (await request(query))
		book_query_cache.data = data
		update_cache()
	else:
		print("Using cache for '%s'" % query)

	return book_query_cache.data


func fetch_book_id(id: String):
	var query = "book/%s" % id

	var book_query: Dictionary = cache.get_or_add("query", {})
	var book_query_cache: RanobeCache = book_query.get_or_add(query, RanobeCache.new())
	
	if book_query_cache.invalid:
		var data = (await request(query))
		book_query_cache.data = data
		update_cache()
	else:
		print("Using cache for '%s'" % query)

	return book_query_cache.data
