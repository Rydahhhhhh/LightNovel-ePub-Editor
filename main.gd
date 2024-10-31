extends Control

signal book_saved

var book: Epub

@onready var select_dialog = FileDialog.new()
@onready var save_dialog = FileDialog.new()

func _ready() -> void:
	book = Epub.new("C:\\Users\\rydie\\Downloads\\DanMachi - Volume 01 [Yen Press][Kobo].epub")
	#print(book)
	#return
	var data = await RanobeDb.fetch_book(book.title.value)
	
	for book_data in data.books:
		if book_data.title == book.title.value:
			update_book(book_data.id)
	
	return
	for dialog in [select_dialog, save_dialog]:
		dialog.set_use_native_dialog(true)
		
		dialog.access = FileDialog.ACCESS_FILESYSTEM
		
		dialog.add_filter("*.epub", "Ebooks")
		dialog.move_to_foreground()
	
	select_dialog.file_selected.connect(format_epub)
	select_dialog.files_selected.connect(format_epubs)
	save_dialog.file_selected.connect(save_location_selected)
	
	select_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	return
	
func format_epub(file_path: String):
	
	book = Epub.new(file_path)
	#book.format_as_ln()
	print(book)
	
	await book_saved

func format_epubs(file_paths):
	for file_path in file_paths:
		format_epub(file_path)

func select_file():
	
	select_dialog.popup()

func save_file():
	
	save_dialog.popup()

func save_location_selected(file_path: String):
	
	if book == null:
		print("null epub")
		return
	book.save(file_path)
	book_saved.emit()

func update_book(randobe_id: int):
	var book_data = await RanobeDb.fetch_book_id(str(randobe_id))
	
	book.title.value = book_data.title
	book.title.sort_by = book_data.title
	
	var desc = book_data.description
	if desc.contains("\n"):
		desc = desc.split("\n")[0]
	
	book.description.value = desc
	
	book.language.value = book_data.lang
	
	var series_data = await RanobeDb.fetch_series_id(str(book_data.series.id))
	
	var publication_status = series_data.publication_status
	book.series.value = series_data.title
	
	for staff in series_data.staff:
		var staff_name: String = staff.name if staff.lang == "en" else staff.romaji
		
		var reverse: Callable = func(s: String):
			var names = s.split(" ")
			names.reverse()
			return ", ".join(names)
		
		var staff_name_sort = staff_name if staff.lang == "en" else reverse.call(staff_name)
		book.creators.add_creator(staff_name, staff.role_type, staff_name_sort)
	
	for subject in series_data.tags:
		if subject.ttype == "genre":
			pass
	print(book)
	return
