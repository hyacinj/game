class_name GameConfig

# ---- Terrain ----
const BLOCK_SIZE: int = 40
const TERRAIN_ROWS: int = 6
const TERRAIN_COLS: int = 48
const BLOCK_HP: int = 60
const TERRAIN_Y_OFFSET: float = 250.0

# ---- Units ----
const PLAYER_HP: int = 100
const PLAYER_X: float = -750.0
const ENEMY_HP: int = 60

# ---- Projectile ----
const MAX_POWER: float = 800.0
const MIN_POWER: float = 200.0
const PROJECTILE_RADIUS: float = 12.0
const EXPLOSION_RADIUS: float = 100.0
const BASE_DAMAGE: int = 25
const GRAVITY: float = 600.0

# ---- P1: AimLine ----
const AIM_SIM_STEPS: int = 60
const AIM_SIM_DT: float = 0.05

# ---- P1: Scatter ----
const SCATTER_COUNT: int = 3
const SCATTER_SPREAD: float = 30.0  # degrees

# ---- P1: Wind ----
const WIND_FORCE_MAX: float = 80.0

# ---- P1: Energy ----
const MAX_ENERGY: int = 3
const STARTING_ENERGY: int = 3

# ---- P1: Cards ----
const MAX_HAND_SIZE: int = 10
const DRAW_PER_TURN: int = 5
const STARTING_DECK_SIZE: int = 6

# ---- P1: Status ----
const BURN_DAMAGE_PER_TURN: int = 5
const FREEZE_SLOW_RATIO: float = 0.5
const STATUS_DEFAULT_DURATION: int = 3
