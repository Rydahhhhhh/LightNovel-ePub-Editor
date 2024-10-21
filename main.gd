extends Control

signal formatted

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
	book = Epub.new(file_path)
	book.title = "DANMACHI"
	await formatted

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
	formatted.emit()
