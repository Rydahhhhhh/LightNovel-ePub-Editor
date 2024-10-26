class_name RanobeCache extends Resource

signal updated

@export_storage var data: set = set_data
@export var last_update: int

var expired: bool:
	get():
		var time_since_update = Time.get_unix_time_from_system() - last_update
		var days_since_update = Time.get_date_dict_from_unix_time(time_since_update).day - 1
		return days_since_update > 7

var invalid: bool:
	get():
		return data == null or expired

func update_expiry():
	last_update = Time.get_unix_time_from_system()
	return

func set_data(_data):
	data = _data
	update_expiry()
	updated.emit(data)
