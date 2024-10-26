@tool
extends HTTPManager

signal request_finished(response)
signal request_failed()

func fetch(url: String):
	var request = job(url)
	request.on_success(request_finished.emit)
	request.on_failure(request_finished.emit)
	request.fetch()
	
	var response = (await request_finished)
	
	while response.request_query != url:
		response = (await request_finished)
	await job_completed
	if response.response_code != 200:
		return {}
	return response.fetch()
