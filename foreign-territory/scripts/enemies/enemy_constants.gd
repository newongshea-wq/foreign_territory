extends RefCounted
class_name EnemyConstants

# one tile of the room grid(30x30 tiles)
const TILE: float = 30.0
# one heart of player health to HealthComponent(twice)
const HEART: float = 2.0
# difficulty growth per level and room within level
const LEVEL_SCALE: float = 1.2
const ROOM_SCALE: float = 1.05
# enemy projectiles travel 40-60% of base player speed(tbd)
const PROJECTILE_SPEED_RATIO: float = 0.5


# returns damage of one player hit
static func hit() -> float:
	return PlayerController.BASE_DAMAGE


# returns speed enemy projectiles are measured against
static func base_player_speed() -> float:
	return PlayerController.BASE_SPEED


# converts a distance in room tiles to pixels
static func tiles_to_pixels(tiles: float) -> float:
	return tiles * TILE


# converts a pixel distance back into room tiles
static func pixels_to_tiles(pixels: float) -> float:
	return pixels / TILE


# converts a damage value in hearts to HealthComponent units
static func hearts_to_damage(hearts: float) -> float:
	return hearts * HEART


# returns the difficulty multiplier for health, damage and rewards at a given depth
static func get_level_scalar(floor_number: int, room_number: int) -> float:
	var level_depth := maxf(0.0, float(floor_number - 1))
	var room_depth := maxf(0.0, float(room_number - 1))
	return pow(LEVEL_SCALE, level_depth) * pow(ROOM_SCALE, room_depth)