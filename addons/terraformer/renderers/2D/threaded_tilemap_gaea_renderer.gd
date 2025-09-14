@tool
class_name ThreadedTilemapGaeaRenderer
extends TilemapTerraRenderer
## A threaded verison of [TilemapTerraRenderer], allowing rendering code to run parallel to the main thread of your game.
##
## Wrapper for [TilemapTerraRenderer] that runs multiple [method TerraRenderer2D._draw_area] calls
##  in parallel using the [WorkerThreadPool].
## @experimental
##
## @tutorial(Optimization): https://benjatk.github.io/Gaea/#/tutorials/optimization

## Whether or not to pass calls through to the default TilemapGaeaRenderer,
##  instead of threading them.
@export var threaded: bool = true
## Decides the maximum number of WorkerThreadPool tasks that can be created
##  before queueing new tasks. A negative value (-1) means there is no limit.
@export_range(-1, 1000, 1, "exp", "or_greater") var task_limit: int = -1

var _queue: TerraTaskQueue


func _process(_delta):
	if not threaded:
		return
	if _queue:
		_queue.process()


func _draw_area(area: Rect2i) -> void:
	if not threaded:
		super(area)
		return

	_ensure_queue()

	var _task:Callable = func ():
		super._draw_area(area)

	_queue.enqueue(_task)


func run_task(_task:Callable):
	if not _task:
		return
	_ensure_queue()
	_queue.enqueue(_task)


func _ensure_queue() -> void:
	if _queue != null:
		return
	_queue = TerraTaskQueue.new()
	_queue.task_limit = task_limit
