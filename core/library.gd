extends Library

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	logger = Log.get_logger("vkCube", Log.LEVEL.INFO)
	logger.info("vkCube Library loaded")


# Return a list of Games. Called by the LibraryManager.
func get_library_launch_items() -> Array[LibraryLaunchItem]:
	var game_titles = [
		"Star Odyssey", "Quantum Rush", "Pixel Quest", "Cyber Siege", "Galactic Wars",
		"Mystic Realms", "Neon Drift", "Echo Protocol", "Shadow Tactics", "Astro Strike",
		"Time Warp", "Gravity Shift", "Code Breakers", "Lunar Legacy", "Solar Siege",
		"Phantom Core", "Digital Dawn", "Cosmo Clash", "Orbital Defense", "Void Runner",
		"Chrono Trigger", "Space Haven", "Pixel Pirates", "Quantum Leap", "Star Forge",
		"Nightmare Circuit", "Aether Storm", "Glitch Runner", "Meteor Mash", "Skybound",
		"Data Flux", "Neon Nexus", "Ghost Protocol", "Starlight Sprint", "Eclipse Wars",
		"Binary Blast", "Cosmic Drift", "Portal Runner", "Astro Assault", "Time Loop",
		"Spectral Shift", "Nova Strike", "Circuit Breaker", "Lunar Landing", "Solar Flux",
		"Dark Orbit", "Digital Dimension", "Stellar Clash", "Void Voyage", "Chrono Clash",
		"Space Raiders", "Pixel Pulse", "Quantum Quest", "Star Command", "Net Runner",
		"Aether Wars", "Glitch Ghost", "Meteor Storm", "Sky Fortress", "Data Storm",
		"Neon Orbit", "Shadow Circuit", "Starfall", "Eclipse Runner", "Binary Stars",
		"Cosmic Quest", "Portal Storm", "Astro Arena", "Time Trials", "Spectral Space",
		"Nova Rush", "Circuit Rush", "Lunar Ops", "Solar Strike", "Dark Nebula",
		"Digital Dreams", "Stellar Storm", "Void Walker", "Chrono Wars", "Space Strike",
		"Pixel Power", "Quantum Core", "Star Hunter", "Net Wars", "Aether Quest",
		"Glitch Space", "Meteor Mayhem", "Sky Strike", "Data Dash", "Neon Storm",
		"Shadow Ops", "Starstrike", "Eclipse Protocol", "Binary Realm", "Cosmic Core",
		"Portal Wars", "Astro Ops", "Time Shift", "Spectral Storm", "Nova Core"
	]
	
	var result: Array[LibraryLaunchItem] = []
	
	for i in range(100):
		var item: LibraryLaunchItem = LibraryLaunchItem.new()
		var random_game = game_titles[randi() % game_titles.size()]
		
		item.name = random_game
		item.command = random_game.to_lower().replace(" ", "_")
		item.args = []
		item.tags = [random_game.to_lower().replace(" ", "_")]
		item.installed = true
		
		result.append(item)
	
	return result
