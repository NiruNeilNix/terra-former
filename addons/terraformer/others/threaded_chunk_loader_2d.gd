@tool
class_name ThreadedChunkLoader2D
extends ChunkLoader2D

@export var threaded: bool = true

var _queue: TerraTaskQueue
var _pending: Callable


func _process(_delta):
	if not threaded:
		super(_delta)
		return
	if _queue:
		_queue.process()
	super(_delta)


func _update_loading(actor_position: Vector2i) -> void:
	if not threaded:
		super(actor_position)
		return

	_ensure_queue_initialized()
	var _job:Callable = func ():
		super._update_loading(actor_position)

	_pending = _job
	run_job(_pending)


func run_job(_job:Callable):
	if not _job:
		return
	_queue.enqueue(_job)


func _ensure_queue_initialized() -> void:
	if _queue != null:
		return
	_queue = TerraTaskQueue.new()
	# single-thread behavior for chunk loader queueing; limit to one at a time
	_queue.task_limit = 1
