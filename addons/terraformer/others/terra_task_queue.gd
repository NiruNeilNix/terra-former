@tool
class_name TerraTaskQueue
extends RefCounted

@export var task_limit: int = -1

var _queued: Array[Callable] = []
var _tasks: PackedInt32Array = []


func enqueue(task: Callable) -> void:
	if task == null:
		return
	if _has_capacity():
		_run(task)
		return
	_queued.push_back(task)


func process() -> void:
	_cleanup_completed_tasks()
	_drain_queue_if_possible()


func _run(task: Callable) -> void:
	var id := WorkerThreadPool.add_task(task, false, "Terra Task")
	_tasks.append(id)


func _cleanup_completed_tasks() -> void:
	for t in range(_tasks.size() - 1, -1, -1):
		if WorkerThreadPool.is_task_completed(_tasks[t]):
			WorkerThreadPool.wait_for_task_completion(_tasks[t])
			_tasks.remove_at(t)


func _drain_queue_if_possible() -> void:
	if task_limit >= 0:
		while _tasks.size() < task_limit and not _queued.is_empty():
			_run(_queued.pop_front())
		return
	while not _queued.is_empty():
		_run(_queued.pop_front())


func _has_capacity() -> bool:
	if task_limit < 0:
		return true
	return _tasks.size() < task_limit
