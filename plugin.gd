extends Plugin

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	logger = Log.get_logger("TemplatePlugin", Log.LEVEL.DEBUG)
	logger.info("Template plugin loaded")

# Load the Library implementation
	var library: Library = load(plugin_base + "/core/library.tscn").instantiate()
	add_child(library)
