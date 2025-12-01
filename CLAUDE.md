# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**AxiumForge – SDF Asteroids** is a modern, stylized Asteroids-inspired game built with LÖVE 2D (Lua), where all graphics are generated from SDF/TSDF (Signed Distance Field/Truncated Signed Distance Field) data. No bitmap assets are used - everything is drawn mathematically from parameters.

### Core Concepts
- **Engine**: LÖVE 11.x (Lua-based 2D game framework)
- **Graphics**: Pure SDF/TSDF-based rendering (no PNG/JPG assets)
- **Physics**: Box2D for collision detection, ricochet, impacts, and movement
- **Data-driven**: All game objects defined in Lua tables or JSON files
- **Style**: "Glow vector look" with sharp SDF curves and clean light edges

### Game Vision
- Animated solar system background with parallax
- Avoid meteors and shoot with railgun
- Prevent meteors from passing through an inner protected zone
- Meteors fragment realistically when hit using TSDF-based destruction

## Development Commands

Since this is a LÖVE project, use these commands:

### Running the Game
```bash
love .
```

### Development Workflow
- Edit Lua files directly
- LÖVE hot-reloads on file changes (if configured)
- No build step required for Lua code

## Project Architecture

### Directory Structure

```
project_root/
  main.lua              # Main game loop and initialization
  conf.lua              # LÖVE configuration
  src/
    core/
      game_state.lua    # Game state management
      input.lua         # Input handling
      physics.lua       # Box2D physics setup and management
    entities/
      ship.lua          # Player ship with rotation and thrust
      meteor.lua        # Meteor entities with SDF definitions
      railgun.lua       # Railgun weapon system
    render/
      draw_sdf.lua      # SDF rendering functions
      background.lua    # Animated solar system background
      ui.lua            # Minimal UI (score, shields, meteor count)
    data/
      sdf_meteors.lua   # SDF/TSDF meteor definitions
      settings.lua      # Game configuration parameters
  assets/
    fonts/              # Font files only (no graphics)
    references/         # Reference images of authentic SDF/TSDF objects for implementation guidance
  docs/                 # Project documentation
```

### Module Responsibilities

**`data/`**: Contains all SDF/TSDF definitions and game parameters
- Meteor shapes defined as primitive combinations (circles, ellipses, polygons)
- Density, mass, and fragmentation rules
- All parameters externalized (no hardcoded values in logic)

**`entities/`**: Game objects with Box2D physics
- Each entity manages its own physics body
- Collision callbacks and interaction logic
- Entity lifecycle (spawn, update, destroy, fragment)

**`render/`**: All drawing code
- SDF primitive rendering via `love.graphics`
- Glow effects using layered SDF circles
- Background parallax system
- Minimal UI overlays

**`core/`**: Game engine fundamentals
- Physics world management
- Input polling and state
- Game state transitions

## SDF/TSDF System

### Using Reference Images

The `assets/references/` directory contains PNG images showing authentic SDF/TSDF objects. When implementing meteor shapes and visual effects:
- Study these images to understand the visual characteristics of proper SDF rendering
- Use them as ground truth for meteor appearance, shape complexity, and glow effects
- Match the visual style: sharp edges, clean curves, and characteristic SDF glow
- These represent the target aesthetic for all procedurally generated objects

### Meteor Definition Format

Meteors are defined using SDF primitives in Lua tables:

```lua
{
  id = "meteor_big_01",
  type = "sdf_meteor",
  primitives = {
    { shape = "circle", r = 40 },
    { shape = "circle", r = 25, offset = {x=10, y=-15} }
  },
  density = 1.0,
  fracture_threshold = 0.7
}
```

### TSDF Fragmentation

When a meteor is hit by the railgun:
1. Create 2-3 smaller meteors
2. Inherit shape but scale down
3. Apply velocity variation to fragments
4. Each fragment becomes a new Box2D body with appropriate mass

### SDF Rendering

- Primitives drawn directly from parameters using `love.graphics`
- Glow effects created with multiple SDF-derived circles
- No texture mapping required

## Physics System (Box2D)

### Ship Physics
- Polygon-based Box2D body
- Rotation controls (left/right)
- Forward thrust
- Minimal friction for space-like feel

### Railgun Mechanics
- **Instant raycast** or ultra-fast projectile
- Uses `world:rayCast()` for collision detection
- Penetrates through multiple meteors
- Triggers TSDF fragmentation on impact

Example raycast callback:
```lua
function rayCallback(fixture, x, y, xn, yn, fraction)
    local meteor = fixture:getUserData()
    meteor:applyDamage(railgunPower, x, y, xn, yn)
    return -1   -- railgun continues through all objects
end
```

### Meteor Spawning
- Spawn in ring outside visible area
- Semi-random trajectories through playfield
- Collision between meteors can create chain reactions (future iteration)

### Protected Zone
- Inner zone that meteors must not cross
- Crossing triggers penalty or game over condition

## Visual Style Guidelines

### Solar System Background
- SDF-based planets in background layers
- Slow orbital animation
- Color gradients for visual depth

### Meteor Appearance
- Glow outlines for visibility
- Crater details as additional small primitives
- Multi-layer rendering for depth effect

### Railgun Visual Effects
- Glowing beam with:
  - Thin core line
  - Wider glow layers
  - Lens flare/star spikes (optional)
- Screen shake on fire
- Particle effects at impact points

### UI Design
- Minimalist approach
- Display: score, shields/lives, active meteor count
- Clean typography with minimal visual clutter

## CSG Operations (Future)

The codebase references CSG (Constructive Solid Geometry) operations for advanced SDF manipulation:

### Basic Operations
- `union(a, b)`: Combine two SDF shapes
- `intersect(a, b)`: Intersection of shapes
- `subtract(a, b)`: Boolean subtraction
- `smoothUnion(a, b, k)`: Smooth blending between shapes

### Splitting Meteors
```lua
function split_in_two(baseSDF, hitPoint, hitNormal)
    local splitPlane = plane(hitPoint, hitNormal)
    local left  = intersect(baseSDF, splitPlane)
    local right = intersect(baseSDF, plane(hitPoint, -hitNormal))
    return left, right
end
```

## MVP Scope

The minimum viable product should include:

1. Basic LÖVE game loop with proper initialization
2. Player ship with rotation and thrust controls
3. Meteor spawning system (ring-based)
4. Railgun firing and collision detection
5. SDF data file defining at least 3 meteor types
6. Animated background with sun/planets
7. Basic UI showing game state

## Code Quality Guidelines

### Architecture Principles
- **Modular design**: Keep files focused and independent
- **Pure functions**: Avoid side effects where possible
- **No hardcoded values**: All parameters come from `data/` modules
- **Data-driven**: Game objects defined by tables, not code

### LÖVE-Specific Patterns
- Use `love.load()` for one-time initialization
- `love.update(dt)` for game logic (physics, AI, timers)
- `love.draw()` only for rendering (no logic)
- Separate input handling into dedicated module

### Performance Considerations
- SDF calculations can be expensive - optimize hot paths
- Cache SDF computations where possible
- Box2D bodies are costly - reuse and pool when appropriate
- Profile rendering if frame rate drops

## Future Iterations (Not MVP)

These features are documented but should NOT be implemented in the MVP:

- Full data-driven TSDF fragmentation with mass calculation
- Port to LÖVR (3D VR version) using same SDF data
- Raymarch-based GLSL shaders for advanced effects
- Dynamic difficulty scaling
- Lore-based progression system
- Meteor-meteor collision chain reactions

## Important Files to Maintain

- **TODO**: Track feature decisions, limitations, and next steps
- **CHANGELOG**: Document all changes to the codebase
- **docs/PROJECT/project.md**: Complete project specification (Danish)
- **docs/background/**: Design discussions and technical deep-dives

## Development Notes

- The project documentation is in Danish, but all code and comments must be in English
- Reference images in `assets/references/` show authentic SDF/TSDF objects to guide implementation of meteor shapes and visual style
- The RAG, TODO, and CHANGELOG files exist but are currently empty
- No actual game code has been written yet - this is a greenfield project
