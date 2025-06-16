class_name Issue extends RefCounted

enum Severity {ERROR, WARNING, INFO}
enum Status {UNRESOLVED, RESOLTUION_REQUIRED, RESOLVED, INFERRED, PENDING, IGNORED, INVALID}

var severity: Severity
var message: String
var status: Status
var handler: Handler

func _init(severity: Severity, status := Status.UNRESOLVED, message := "", handler: Handler = Handler.empty()) -> void:
	self.severity = severity
	self.message = message
	self.status = status
	self.handler = handler
	return

func resolve():
	return

static func Info(message: String):
	return Issue.new(Severity.INFO, Status.RESOLVED, message)

class Handler extends RefCounted:
	var handler_fn: Callable
	var handler_options: Array
	var msg: String
	var is_empty := false
	
	func _init(handler_fn: Callable = func(x): return x, handler_options: Array = [], ui_message := "") -> void:
		self.handler_fn = handler_fn
		self.handler_options = handler_options
		self.msg = ui_message
		return 
	
	static func empty() -> Handler:
		var h = Handler.new()
		h.is_empty = true
		return h
