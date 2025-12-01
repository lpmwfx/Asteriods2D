# PROJEKTOPLÆG: "AxiumForge – SDF Asteroids"

## 0. Arbejdsinstruks til AI‑coder

* Sprog: **Lua** til **LÖVE 11.x**.
* Arkitektur: modulær, rene filer, ingen hardcodede tal som ikke stammer fra data.
* Fokus: **SDF/TSDF som datakilde**, Box2D fysik, og en hurtig MVP.
* Leverancer:

  * Kørbart LÖVE‑projekt
  * `README.md`
  * `TODO.md` med valg, begrænsninger og næste trin

---

## 1. Spilvision

Et moderne, stiliseret *Asteroids*‑inspireret spil, hvor al grafik bygges af **SDF/TSDF data**. Intet bitmap‑materiale. Alt tegnes matematisk fra parametre.

### Hovedideer

* Baggrund: Animeret solsystem i parallax.
* Gameplay: Undgå meteorer, skyd med **railgun**, forhindre meteorer i at passere en indre beskyttet zone.
* Fysik: Box2D i 2D.
* Stil: "Glow vector look" – skarpe SDF‑kurver, rene lyskanter.

---

## 2. Tekniske rammer

**Engine:** LÖVE 2D (Lua)

**Dimensioner:** 2D gameplay med illusion af 2.5D.

**Grafik:**

* Ingen PNG/JPG.
* Kun SDF/TSDF + primitive shapes der tegnes fra data.

**Fysik:**

* Box2D til bevægelse, ricochet, impacts og kollisionshåndtering.

**Dataformat:**

* Lua‑tabeller eller JSON‑filer med:

  * SDF primitive former
  * Masse, densitet
  * Fragmenteringsregler

---

## 3. SDF/TSDF Design

### Meteorer (SDF‑definerede)

* Bygges af primitive shapes (cirkler, ellipser, polygoner).
* Eksempel:

```
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

### TSDF / Fragmentering

* Når meteoren rammes:

  * Lav 2–3 nye mindre meteorer.
  * Arv form, men skalér ned.
  * Variation i retning og speed.

### Rendering

* Tegnes direkte fra SDF‑parametre via `love.graphics`.
* To‑lag glow kan laves med to SDF‑afledte cirkler.

---

## 4. Gameplay & fysik

### Rumskib

* Rotation venstre/højre.
* Thrust fremad.
* Box2D polygon‑krop.
* Minimal friktion → rumfølelse.

### Railgun

* Instant raycast eller ultra‑hurtigt projektil.
* Trigger fragmentering på meteorer.

### Meteorer

* Spawn i ring uden for skærmen.
* Driver gennem banen i semi‑tilfældige baner.
* Kollision meteorit–meteorit kan i senere iteration skabe kædereaktioner.

### Beskyttet zone

* Hvis meteorer krydser indre zone → straf eller game over.

---

## 5. Visuel stil

### Solsystem

* SDF‑planeter i baggrundslag.
* Langsom orbit og farvegradienter.

### Meteorer

* Glow outlines, crater‑detaljer som små ekstra primitiver.

### UI

* Minimalistisk: score, liv/shields, antal meteorer.

---

## 6. Arkitektur

**Mappestruktur:**

```
project_root/
  main.lua
  conf.lua
  src/
    core/
      game_state.lua
      input.lua
      physics.lua
    entities/
      ship.lua
      meteor.lua
      railgun.lua
    render/
      draw_sdf.lua
      background.lua
      ui.lua
    data/
      sdf_meteors.lua
      settings.lua
  assets/
    fonts/
  README.md
  TODO.md
```

**Roller:**

* `data/`: SDF/TSDF beskrivelser.
* `entities/`: objekter + Box2D.
* `render/`: al tegning.

---

## 7. MVP‑scope

AI‑coder skal levere:

1. Grundloop i LÖVE.
2. Rumskib med rotation + thrust.
3. Meteor‑spawn i ring.
4. Railgun‑skud + collision.
5. SDF‑datafil for meteorer.
6. Baggrund med sol/planeter.
7. README + TODO.

---

## 8. Fremtidige iterationer (ikke i MVP)

* Fuld data‑drevet TSDF flækning.
* Overførsel til LÖVR med samme SDF‑data.
* Raymarch‑agtig shaders.
* Dynamisk sværhedsgrad.
* Lore‑baseret progressionssystem.

---

## 9. Outputkrav

* Kørbart LÖVE projekt.
* README.md med instruktioner.
* TODO.md med fremtidige trin.
* Koden skal være klar til iteration.
