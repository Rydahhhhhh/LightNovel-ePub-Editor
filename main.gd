extends Control

var book: Epub
var files = []
var save_location: set = set_save_location

@onready var select_dialog = FileDialog.new()
@onready var save_dialog = FileDialog.new()

func _ready() -> void:
	for dialog in [self.select_dialog, self.save_dialog]:
		dialog.set_use_native_dialog(true)
		
		dialog.access = FileDialog.ACCESS_FILESYSTEM
		
		dialog.add_filter("*.epub", "Ebooks")
		dialog.move_to_foreground()
	
	self.select_dialog.file_selected.connect(self.files.append)
	self.select_dialog.files_selected.connect(self.files.append_array)
	save_dialog.dir_selected.connect(set_save_location)
	
	self.select_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	self.save_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	return

func set_save_location(to):
	save_location = to

func select_file() -> void:
	self.select_dialog.popup()

func save_file():
	self.save_dialog.popup()

func _on_format_pressed() -> void:
	print(self.files)
	print(self.save_location)
	if self.save_location != null:
		for book_path in self.files:
			await self.format_epub(book_path)
	self.files.clear()
	self.save_location = null

func format_epub(file_path: String):
	book = Epub.new(file_path)
	
	var data = await RanobeDb.fetch_book(book.title)
	for book_data in data.books:
		if book_data.title == book.title:
			await update_book(book_data.id)
	book.save(self.save_location + "\\" + book.title_sort.validate_filename().replace("_", "") + ".epub")
	return 


func update_book(randobe_id: int):
	var book_data = await RanobeDb.fetch_book_id(str(randobe_id))
	
	book.title = book_data.title
	book.title_sort = book_data.title
	
	var desc = book_data.description
	if desc.contains("\n"):
		desc = desc.split("\n")[0]
	

	book.description = desc
	book.language = book_data.lang
	
	var series_data = await RanobeDb.fetch_series_id(str(book_data.series.id))
	
	book.series = series_data.title
	
	for staff in series_data.staff:
		var staff_name: String = staff.name if staff.lang == "en" else staff.romaji
		

	book.series = series_data.title
	
	book.clear_creators()
	
	for staff in series_data.staff:
		var staff_name = staff.name if staff.lang == "en" else staff.romaji
		if staff_name == null:
			continue

		var reverse: Callable = func(s: String):
			var names = s.split(" ")
			names.reverse()
			return ", ".join(names)
		
		var staff_name_sort = staff_name if staff.lang == "en" else reverse.call(staff_name)
		book.add_creator(staff_name, staff.role_type, staff_name_sort)
	
	for tag in series_data.tags:
		#if tag["ttype"] == "genre":
		book.add_genre(tag.name)
	
	for data in series_data.books:
		book.series_index = data.sort_order
	
	return
