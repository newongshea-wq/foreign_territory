extends Resource
class_name AttackData

@export_group("Identity")
@export var id: StringName = &""

@export_group("Loop timing (seconds)")
# telegraph window
@export_range(0.0, 3.0, 0.05) var windup_time: float = 0.3
# window where hitbox is live, projectile is released
@export_range(0.0, 3.0, 0.05) var active_time: float = 0.1
# punish window missed atk
@export_range(0.0, 3.0, 0.05) var recover_time: float = 0.4
@export_range(0.0, 20.0, 0.1) var cooldown: float = 3.0

@export_group("Targeting (tiles)")
@export_range(0.0, 40.0, 0.5) var range_tiles: float = 3.0
# attacks with dead zone, for example, boss cannot charge point blank
@export_range(0.0, 40.0, 0.5) var minimum_range_tiles: float = 0.0
@export var requires_line_of_sight: bool = true

@export_group("Damage")
@export var damage_hearts: float = 0.5
@export_range(0.0, 600.0, 10.0) var knockback: float = 0.0

@export_group("Presentation")
@export var windup_animation: StringName = &"windup"
@export var attack_animation: StringName = &"attack"
@export var recover_animation: StringName = &"recover"
# wip.
#@export var windup_sfx: AudioStream
#@export var attack_sfx: AudioStream


# returns state the machine enters to execute attack, but subclasses override
func get_attack_state() -> StringName:
	return &"attack"


# returns trigger range in pixels
func get_range() -> float:
	return EnemyConstants.tiles_to_pixels(range_tiles)


# returns closest distance this attack should start from
func get_minimum_range() -> float:
	return EnemyConstants.tiles_to_pixels(minimum_range_tiles)

# reports whether target distance allows attack to start
func is_in_range(distance_pixels: float) -> bool:
	return distance_pixels <= get_range() and distance_pixels >= get_minimum_range()


# returns damage in HealthComponent units after depth scaling
func resolve_damage(difficulty_scalar: float = 1.0) -> float:
	return EnemyConstants.hearts_to_damage(damage_hearts) * difficulty_scalar


# returns how long full windup will be, active and recover sequence takes
func get_total_time() -> float:
	return windup_time + active_time + recover_time
