extends Control

signal book_saved

var book: Epub

@onready var select_dialog = FileDialog.new()
@onready var save_dialog = FileDialog.new()

func _ready() -> void:
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
	return
	book = Epub.new(file_path)
	book.format_as_ln()
	
	await book_saved

func format_epubs(file_paths):
	return
	for file_path in file_paths:
		format_epub(file_path)

func select_file():
	return
	select_dialog.popup()

func save_file():
	pass
	#save_dialog.popup()

func save_location_selected(file_path: String):
	return
	if book == null:
		print("null epub")
		return
	book.save(file_path)
	book_saved.emit()
