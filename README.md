# AxiumForge - SDF Asteroids

Et moderne, stiliseret Asteroids-inspireret arcade shooter spil, hvor **al grafik genereres matematisk fra SDF/TSDF data** (Signed Distance Fields / Truncated Signed Distance Fields). Ingen bitmap assets - alt tegnes proceduralt.

![LÖVE Version](https://img.shields.io/badge/L%C3%96VE-11.5-EA316E?logo=love2d)
![Language](https://img.shields.io/badge/Language-Lua-000080?logo=lua)
![Physics](https://img.shields.io/badge/Physics-Box2D-green)

## 🎮 Gameplay

Undgå meteorer i rummet, skyd med din penetrerende railgun, og beskyt den indre zone!

### Kontroller
- **←/→ Piltaster**: Roter rumskib
- **↑ Piltast**: Thrust fremad
- **SPACE**: Affyr railgun
- **P**: Pause
- **ESC**: Afslut

### Gameplay Features
- **TSDF Fragmentation**: Meteorer fragmenterer realistisk når de rammes
- **Penetrerende Railgun**: Skud går igennem alle objekter i sin bane
- **Beskyttet Zone**: Lad ikke meteorer krydse den indre cirkel!
- **Fysik-baseret**: Box2D collision med masse og momentum
- **3 Liv**: Ship respawner efter kollision

## 🚀 Kom I Gang

### Krav
- [LÖVE 11.5](https://love2d.org/) eller nyere

### Sådan køres spillet

**macOS / Linux:**
```bash
love .
```

**Windows:**
Træk projektmappen på `love.exe` eller:
```bash
love.exe .
```

**Alternativt** kan du oprette en `.love` fil:
```bash
zip -r AxiumForge.love .
love AxiumForge.love
```

## 🎨 Visuel Stil

**"Glow Vector Look"** kombineret med matematisk SDF rendering:
- Alle objekter tegnes fra distance field primitives
- Multi-layer glow effekter
- Animeret solsystem baggrund med roterende planeter
- Ingen PNG/JPG assets - 100% procedural grafik

## 🔧 Teknisk Overview

### Arkitektur
```
src/
  core/         - Kernesystemer (physics, input, game state)
  entities/     - Spil-entiteter (ship, meteor, railgun)
  render/       - Rendering systemer (SDF, background, UI)
  data/         - Data-definitions (meteor types, settings)
```

### Nøgleteknologier
- **LÖVE 2D (Lua)**: Game engine og framework
- **Box2D**: 2D physics engine (collision, ricochet, momentum)
- **SDF/TSDF**: Mathematisk shape representation
- **Data-drevet design**: Alle parametre i eksterne filer

### SDF System

Meteorer defineres som composite shapes:
```lua
{
  id = "large_01",
  baseRadius = 70,
  primitives = {
    { shape = "circle", r = 70, offset = {x=0, y=0} },
    { shape = "circle", r = 35, offset = {x=20, y=-15} },
    -- ... flere primitives
  },
  density = 2.0,
  fracture_threshold = 150
}
```

### TSDF Fragmentation

Når en meteor rammes:
1. Akkumuleret damage tjekkes mod threshold
2. Hvis overskredet: spawn 2-3 fragmenter
3. Fragmenter skalerer SDF data (0.5x-0.7x)
4. Fragmenter arver fysiske egenskaber (masse, velocity)
5. Minimum størrelse stopper fragmentering

## 📊 Status

### ✅ MVP Komplet (FASE 1)
- [x] Projektstruktur og LÖVE setup
- [x] Core systems (Physics, Input, Game State)
- [x] Data layer (Settings, SDF meteor definitions)
- [x] SDF rendering system med glow
- [x] Ship entity med Box2D physics
- [x] Meteor entity med SDF composites
- [x] Meteor spawning system
- [x] Railgun med penetrerende raycast
- [x] TSDF fragmentation
- [x] Railgun visual effects
- [x] Protected zone collision detection
- [x] Ship-meteor collision detection
- [x] Game over conditions
- [x] Animated background med solar system
- [x] UI system (score, lives, cooldown, FPS)

### 🔜 Næste Features (FASE 2)
Se [TODO](TODO) for detaljeret plan:
- **Visual Enhancement**: 3D-lignende shading, normals, terminators
- **Gameplay Polish**: Screen shake, sound, difficulty scaling
- **Advanced Features**: Shaders, LÖVR port, lore system

## 📁 Projektfiler

- `main.lua` - Hoved game loop
- `conf.lua` - LÖVE konfiguration
- `TODO` - Detaljeret udviklingsplan
- `CHANGELOG` - Implementeringsoversigt
- `CLAUDE.md` - AI assistance guidelines
- `docs/PROJECT/project.md` - Fuld projektspecifikation

## 🎯 Design Filosofi

1. **Data-drevet**: Ingen hardcodede værdier i logik
2. **Modulær**: Klart adskilte ansvar
3. **SDF-baseret**: Al grafik fra matematiske primitives
4. **Fysik-tung**: Box2D driver al bevægelse og kollision
5. **MVP først**: Spilbar iteration før advanced features

## 🐛 Known Issues / Limitations

- Ingen invulnerability frames ved respawn
- Screen shake effekt ikke implementeret endnu
- Background perspektiv er top-down (skal være 20-30 grader)
- Ingen 3D-lignende shading endnu (kun glow)
- Ingen lyd

## 📖 Yderligere Læsning

- [LÖVE Documentation](https://love2d.org/wiki/Main_Page)
- [Box2D Manual](https://box2d.org/documentation/)
- [Signed Distance Fields](https://iquilezles.org/articles/distfunctions2d/)

## 📝 Licens

Dette er et eksperimentelt projekt. Se projektfiler for detaljer.

## 🤖 Development

Dette projekt er udviklet med assistance fra Claude Code (Anthropic).

---

**Nyd spillet! Destruér nogle meteorer! 🚀💥**
