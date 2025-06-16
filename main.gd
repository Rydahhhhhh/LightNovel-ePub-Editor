extends Control

var book: Epub

func _ready() -> void:
	print("Victoria of Many Faces - Volume 2 [Yen Press].epub")
	book = Epub.new("D:\\My Programs\\Godot\\ln-epub-formatter\\Victoria of Many Faces - Volume 2 [Yen Press].epub")
	
	print("\nThe Otome Heroine's Fight for Survival - Volume 01 [J-Novel Club][Premium].epub")
	book = Epub.new("D:\\My Programs\\Godot\\ln-epub-formatter\\The Otome Heroine's Fight for Survival - Volume 01 [J-Novel Club][Premium].epub")
	
	print("\n86 - Volume 01.epub")
	book = Epub.new("D:\\My Programs\\Godot\\ln-epub-formatter\\86 - Volume 01.epub")
	
	print("\nYou Are My Regret - Volume 01 [Yen Press][Kobo].epub")
	book = Epub.new("D:\\My Programs\\Godot\\ln-epub-formatter\\You Are My Regret - Volume 01 [Yen Press][Kobo].epub")
	
	
	return
