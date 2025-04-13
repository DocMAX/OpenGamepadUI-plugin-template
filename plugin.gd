extends Plugin

var library_manager := load("res://core/global/library_manager.tres") as LibraryManager
var settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager
var menu_state_machine := load("res://assets/state/state_machines/menu_state_machine.tres") as StateMachine
var launcher_state := load("res://assets/state/states/game_launcher.tres") as State
var card_scene := load("res://core/ui/components/card.tscn") as PackedScene

# Dictionary to track library items in the custom tab
var _library := {}
var _current_selection := {}
var _refresh_requested := false
var _refresh_in_progress := false

func _ready() -> void:
	logger = Log.get_logger("TemplatePlugin", Log.LEVEL.DEBUG)
	logger.info("Template plugin loaded")

	# Load the Library implementation
	var library: Library = load(plugin_base + "/core/library.tscn").instantiate()
	add_child(library)

	# Duplicate the AllGamesTab and rename it
	var source_node = $"/root/CardUI/MenuContent/FullscreenMenus/LibraryMenu/TabContainer/AllGamesTab"
	var copied_node = source_node.duplicate()
	copied_node.name = "MyCategoryTab"
	var tab_container = $"/root/CardUI/MenuContent/FullscreenMenus/LibraryMenu/TabContainer"
	tab_container.add_child(copied_node)

	# Rename AllGamesGrid to MyCategoryGrid
	var grid_node = copied_node.get_node("MarginContainer/AllGamesGrid")
	if grid_node:
		grid_node.name = "MyCategoryGrid"
	else:
		logger.error("Failed to find MarginContainer/AllGamesGrid in copied node")

	# Add the tab to tabs_state
	var my_category_tab_node := ScrollContainer.new()
	my_category_tab_node.name = "MyCategory"
	var tabs_state := load("res://core/ui/card_ui/library/library_tabs_state.tres") as TabContainerState
	tabs_state.add_tab("MyCategory", my_category_tab_node)

	# Connect library change signals
	var on_library_changed := func(item: LibraryItem):
		logger.debug("Library changed for item: " + item.name + ", queuing refresh")
		queue_refresh()
	library_manager.library_item_added.connect(on_library_changed, CONNECT_DEFERRED)
	library_manager.library_item_removed.connect(on_library_changed, CONNECT_DEFERRED)
	library_manager.library_item_unhidden.connect(on_library_changed, CONNECT_DEFERRED)

	# Initial population
	queue_refresh()


## Queues a refresh of the MyCategoryGrid
func queue_refresh() -> void:
	_refresh_requested = true
	_refresh()


## Handles the actual refresh logic
func _refresh() -> void:
	if not _refresh_requested or _refresh_in_progress:
		return
	_refresh_requested = false
	_refresh_in_progress = true
	await _populate_my_category_grid()
	_refresh_in_progress = false
	_refresh.call_deferred()


# Populates the MyCategoryGrid with library items
func _populate_my_category_grid() -> void:
	var grid_node = $"/root/CardUI/MenuContent/FullscreenMenus/LibraryMenu/TabContainer/MyCategoryTab/MarginContainer/MyCategoryGrid"
	if not grid_node or not grid_node is HFlowContainer:
		logger.error("MyCategoryGrid not found or not an HFlowContainer")
		return

	# Clear existing children
	for child in grid_node.get_children():
		child.queue_free()

	# Define the tab index for MyCategory (arbitrary, unique for tracking)
	var tab_num := 100

	# Get library items (modify this to filter for your category if needed)
	var modifiers: Array[Callable] = [library_manager.sort_by_name]
	var library_items := library_manager.get_library_items(modifiers)

	# Clear the library dictionary for this tab
	_library[tab_num] = {}

	# Populate the grid
	for i in range(library_items.size()):
		var item: LibraryItem = library_items[i]

		# Check if the item should be hidden
		var is_hidden := settings_manager.get_library_value(item, "hidden", false) as bool
		if is_hidden:
			continue

		# Build a card for the library item
		var card := await _build_card(item)

		# Listen for focus changes to track selection
		card.focus_entered.connect(_on_focus_updated.bind(card, tab_num))

		# Listen for library item removed events
		var on_removed := func():
			if tab_num in _library and item.name in _library[tab_num]:
				var tracked_card = _library[tab_num][item.name]
				_library[tab_num].erase(item.name)
				if tab_num in _current_selection and _current_selection[tab_num] == tracked_card:
					_current_selection.erase(tab_num)
				if is_instance_valid(tracked_card):
					tracked_card.queue_free()
				else:
					logger.warn("Attempted to free an invalid card for item: " + item.name)
		item.removed_from_library.connect(on_removed)
		item.hidden.connect(on_removed)

		# Add the card to the grid
		grid_node.add_child(card)

		# Track the card in the library dictionary
		_library[tab_num][item.name] = card

	# Focus the first card if available
	if grid_node.get_child_count() > 0:
		var first_card: Control = grid_node.get_child(0)
		if first_card.visible:
			first_card.grab_focus.call_deferred()


# Builds a card from a library item
func _build_card(item: LibraryItem) -> GameCard:
	var card := card_scene.instantiate() as GameCard
	await card.set_library_item(item)

	# Connect button press to launch the game
	var on_button_up := func():
		launcher_state.data = {"item": item}
		menu_state_machine.push_state(launcher_state)
	card.button_up.connect(on_button_up)

	return card


# Handles focus updates for cards
func _on_focus_updated(card: Control, tab: int) -> void:
	_current_selection[tab] = card

	# Skip scrolling if mouse or touch is used
	var input_manager := get_tree().get_first_node_in_group("InputManager")
	if input_manager:
		if (input_manager as InputManager).current_touches > 0:
			return
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			return

	# Get the scroll container
	var scroll_container := $"/root/CardUI/MenuContent/FullscreenMenus/LibraryMenu/TabContainer/MyCategoryTab" as ScrollContainer
	if not scroll_container:
		return

	# Smoothly scroll to the card
	var tween := get_tree().create_tween()
	tween.tween_property(scroll_container, "scroll_vertical", card.position.y - card.size.y / 3, 0.25)
