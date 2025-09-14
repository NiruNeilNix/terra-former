@tool
class_name ThreadedChunkLoader2D
extends ChunkLoader2D
## @experimental
## A threaded version of [ChunkLoader2D], allowing generation code to run parallel to the main thread of your game.
##
## @tutorial(Chunk Generation): https://benjatk.github.io/Gaea/#/tutorials/chunk_generation
## @tutorial(Optimization): https://benjatk.github.io/Gaea/#/tutorials/optimization

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
