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
