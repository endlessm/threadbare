extends StealthGameLogic
## Custom Stealth Logic for Wizzy Quest
##
## Handles custom defeat animations based on enemy type:
## - Shark enemies trigger "defeated2" animation
## - Other enemies trigger standard "defeated" animation

## Animation name for shark-specific defeat
const SHARK_DEFEAT_ANIMATION := &"defeated2"
## Animation name for standard defeat
const DEFAULT_DEFEAT_ANIMATION := &"defeated"
## Keyword to identify shark sprites
const SHARK_SPRITE_IDENTIFIER := "shark"
## Delay before reloading scene after defeat (in seconds)
const DEFEAT_RELOAD_DELAY := 2.0


func _on_player_detected(player: Player) -> void:
	var alerted_guard := _get_alerted_guard()
	var is_shark_enemy := _is_shark_guard(alerted_guard)
	
	_play_defeat_sequence(player, is_shark_enemy)
	
	await get_tree().create_timer(DEFEAT_RELOAD_DELAY).timeout
	SceneSwitcher.reload_with_transition(Transition.Effect.FADE, Transition.Effect.FADE)


## Returns the first guard in ALERTED state, or null if none found
func _get_alerted_guard() -> Guard:
	for guard: Guard in get_tree().get_nodes_in_group(&"guard_enemy"):
		if guard.state == Guard.State.ALERTED:
			return guard
	return null


## Checks if a guard uses shark sprites based on resource path
func _is_shark_guard(guard: Guard) -> bool:
	if not guard or not guard.sprite_frames:
		return false
	
	var sprite_path := guard.sprite_frames.resource_path.to_lower()
	return SHARK_SPRITE_IDENTIFIER in sprite_path


## Plays the appropriate defeat sequence for the player
func _play_defeat_sequence(player: Player, use_shark_animation: bool) -> void:
	# Set player to defeated mode
	player.mode = Player.Mode.DEFEATED
	await get_tree().process_frame
	
	# Get player nodes
	var animation_player := _get_player_animation_player(player)
	var player_sprite := _get_player_sprite(player)
	
	# Validate nodes exist
	if not animation_player or not player_sprite:
		push_warning("Wizzy Quest: Could not find player AnimationPlayer or Sprite nodes")
		return
	
	# Stop AnimationPlayer to prevent it from overriding the sprite animation
	animation_player.stop()
	
	# Play the appropriate defeat animation
	var animation_name := (
		SHARK_DEFEAT_ANIMATION if use_shark_animation and 
		player_sprite.sprite_frames.has_animation(SHARK_DEFEAT_ANIMATION)
		else DEFAULT_DEFEAT_ANIMATION
	)
	player_sprite.play(animation_name)


## Returns the player's AnimationPlayer node
func _get_player_animation_player(player: Player) -> AnimationPlayer:
	var anim_player := player.get_node_or_null("%AnimationPlayer")
	if not anim_player:
		anim_player = player.get_node_or_null("AnimationPlayer")
	return anim_player


## Returns the player's AnimatedSprite2D node
func _get_player_sprite(player: Player) -> AnimatedSprite2D:
	var sprite := player.get_node_or_null("%PlayerSprite")
	if not sprite:
		sprite = player.get_node_or_null("PlayerSprite")
	return sprite
