extends Resource
class_name EnemyData

@export_group("Identity")
# lookup key for EnemyRegistry and spawn tables
@export var id: StringName = &""
@export var display_name: String = ""
# instanced by wave director
@export var scene: PackedScene
# optional override
@export var sprite_frames: SpriteFrames

@export_group("Health")
# health in player hits at base damage, per design doc's unit
@export_range(0.5, 200.0, 0.5, "or_greater") var base_hits: float = 1.0
# fraction of max health granted as ArmorComponent armor; 0.0 for unarmored
@export_range(0.0, 2.0, 0.05) var armor_fraction: float = 0.0

@export_group("Movement")
@export_range(0.0, 400.0, 1.0, "or_greater") var move_speed: float = 110.0
@export_range(0.0, 4000.0, 10.0) var acceleration: float = 900.0
@export_range(0.0, 4000.0, 10.0) var friction: float = 1200.0

@export_group("Ranges (tiles)")
# distance at which Idle hands over to Chase
@export_range(0.0, 40.0, 0.5) var detect_range_tiles: float = 12.0
# standoff distance held by kiting types; 0.0 closes to contact
@export_range(0.0, 40.0, 0.5) var preferred_range_tiles: float = 0.0
# distance at which enemy gives up and returns to Idle; 0.0 never disengages
@export_range(0.0, 60.0, 0.5) var leash_range_tiles: float = 0.0

@export_group("Combat")
# damage dealt by touching this enemy, in hearts; 0.0 for non-contact types
@export var contact_damage_hearts: float = 0.0
# ordered by priority: first attack whose range brackets target wins
@export var attacks: Array[AttackData] = []
# state machine policy; typed as Resource until enemy_behavior.gd exists
@export var behavior: Resource

@export_group("Horde")
# separation radius for flocking push that keeps hordes from stacking
@export_range(0.0, 6.0, 0.1) var separation_radius_tiles: float = 1.0
# heavier enemies are pushed less and shove more
@export_range(0.1, 10.0, 0.1) var push_weight: float = 1.0
# inclusive range of instances spawned per draw from a spawn table
@export var pack_size: Vector2i = Vector2i.ONE

@export_group("Rewards")
@export var xp_reward: int = 5
# optional on-death behavior: explosion, radiation puddle, split into swarm
@export var death_effect: Resource
# pickup id dropped unconditionally, e.g. Repair Bot's heart
@export var guaranteed_drop_id: StringName = &""


# returns starting health in HealthComponent units for a given depth and tier
func resolve_health(floor_number:int, room_number: int,tier_multiplier:float = 1.0) -> float:
	var scalar := EnemyConstants.get_level_scalar(floor_number, room_number)
	return maxf(1.0, base_hits * EnemyConstants.hit() * scalar * tier_multiplier)


# returns armor in ArmorComponent units, or 0.0 when this type is unarmored
func resolve_armor(floor_number: int, room_number: int, tier_multiplier: float = 1.0) -> float:
	if armor_fraction <= 0.0:
		return 0.0
	return resolve_health(floor_number, room_number, tier_multiplier) * armor_fraction


# returns contact damage in HealthComponent units for a given depth and tier
func resolve_contact_damage(floor_number: int, room_number: int, tier_multiplier: float = 1.0) -> float:
	if contact_damage_hearts <= 0.0:
		return 0.0
	var scalar := EnemyConstants.get_level_scalar(floor_number, room_number)
	return EnemyConstants.hearts_to_damage(contact_damage_hearts) * scalar * tier_multiplier


# returns move speed with a capped depth bonus so late enemies stay dodgeable
func resolve_move_speed(floor_number: int, room_number: int, tier_multiplier: float = 1.0) -> float:
	var scalar := minf(1.65, EnemyConstants.get_level_scalar(floor_number, room_number))
	return move_speed * scalar * tier_multiplier

# returns experience granted on death at a given depth
func resolve_xp(floor_number: int, tier_multiplier: float = 1.0) -> int:
	return int(round(float(xp_reward + floor_number * 2) * tier_multiplier))

# returns aggro distance in pixels
func get_detect_range() -> float:
	return EnemyConstants.tiles_to_pixels(detect_range_tiles)

# returns standoff distance in pixels
func get_preferred_range() -> float:
	return EnemyConstants.tiles_to_pixels(preferred_range_tiles)

# returns disengage distance in pixels, or 0.0 when enemy never disengages
func get_leash_range() -> float:
	return EnemyConstants.tiles_to_pixels(leash_range_tiles)

# returns flocking separation radius in pixels
func get_separation_radius() -> float:
	return EnemyConstants.tiles_to_pixels(separation_radius_tiles)

# returns how many instances this draw should spawn
func roll_pack_size() -> int:
	var low := maxi(1, pack_size.x)
	var high := maxi(low, pack_size.y)
	return randi_range(low, high)


# returns attack with given id, or null when this type has none
func find_attack(attack_id: StringName) -> AttackData:
	for attack in attacks:
		if attack != null and attack.id == attack_id:
			return attack
	return null


# returns first attack in priority order whose range brackets distance
func select_attack(distance_pixels: float)-> AttackData:
	for attack in attacks:
		if attack != null and attack.is_in_range(distance_pixels):
			return attack
	return null


# returns longest attack range in pixels, used to size chase stop distance
func get_longest_attack_range() -> float:
	var longest := 0.0
	for attack in attacks:
		if attack != null:
			longest = maxf(longest, attack.get_range())
	return longest


# creates an unconfigured instance of this enemy's scene
func spawn() -> Node2D:
	if scene == null:
		push_error("EnemyData '%s' has no scene assigned" % id)
		return null
	return scene.instantiate() as Node2D


# returns a list of authoring mistakes, empty when resource is usable
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if String(id).is_empty():
		problems.append("id is empty")
	if scene == null:
		problems.append("scene is unassigned")
	if base_hits <= 0.0:
		problems.append("base_hits must be greater than zero")
	if contact_damage_hearts <= 0.0 and attacks.is_empty():
		problems.append("enemy has no contact damage and no attacks")
	if pack_size.y < pack_size.x:
		problems.append("pack_size.y is smaller than pack_size.x")
	return problems
