Fedt – så får du hele pakken 💥
Jeg deler det op i 4 dele:

1. **Lua CSG-toolbox (engine-agnostisk, LÖVE/LÖVR-klar)**
2. **GLSL SDF raymarch shader med meteorit + split-plane**
3. **AxiumForge JDA/JDW SDF-asteroide skema**
4. **TSDF-baseret fysik/split system (masse, fragmenter)**

Alt er tænkt som *byggesten*, du kan smide direkte ind i din pipeline og lade Claude/GPT bygge videre på.

---

## 1️⃣ Lua CSG-toolbox (SDF + CSG helpers)

Her er et lille rent-Lua modul, der kan bruges både i LÖVE og LÖVR.

```lua
-- sdf.lua
local sdf = {}

-- Simple vec3 helpers (du kan erstatte med din egen vektor-type)
local function vec3(x, y, z) return {x=x, y=y, z=z} end
local function sub(a, b) return vec3(a.x-b.x, a.y-b.y, a.z-b.z) end
local function dot(a, b) return a.x*b.x + a.y*b.y + a.z*b.z end
local function length(v) return math.sqrt(dot(v, v)) end

sdf.vec3 = vec3
sdf.sub  = sub
sdf.dot  = dot
sdf.length = length

-------------------------------------------------
-- PRIMITIVER
-------------------------------------------------

function sdf.sphere(center, radius)
    return function(p)
        local d = sub(p, center)
        return length(d) - radius
    end
end

function sdf.box(center, halfExtents)
    -- Axis aligned box
    return function(p)
        local q = sub(p, center)
        q = { x = math.abs(q.x) - halfExtents.x,
              y = math.abs(q.y) - halfExtents.y,
              z = math.abs(q.z) - halfExtents.z }
        local outsidesq = math.max(q.x, 0)^2 + math.max(q.y, 0)^2 + math.max(q.z, 0)^2
        local inside    = math.min(math.max(q.x, math.max(q.y, q.z)), 0.0)
        return math.sqrt(outsidesq) + inside
    end
end

-- Uendeligt plan: alt på én side afstand = pos, anden side = neg
function sdf.plane(pointOnPlane, normal)
    local nlen = length(normal)
    local n = {x = normal.x / nlen, y = normal.y / nlen, z = normal.z / nlen}
    return function(p)
        return dot(sub(p, pointOnPlane), n)
    end
end

-------------------------------------------------
-- CSG OPERATIONER
-------------------------------------------------

function sdf.union(a, b)
    return function(p)
        return math.min(a(p), b(p))
    end
end

function sdf.intersect(a, b)
    return function(p)
        return math.max(a(p), b(p))
    end
end

function sdf.subtract(a, b)
    -- A minus B
    return function(p)
        return math.max(a(p), -b(p))
    end
end

-- Smooth varianter
function sdf.smoothUnion(a, b, k)
    return function(p)
        local da = a(p)
        local db = b(p)
        local h = math.max(0.0, math.min(1.0, 0.5 + 0.5*(db-da)/k))
        return (1.0-h)*db + h*da - k*h*(1.0-h)
    end
end

function sdf.smoothSubtract(a, b, k)
    return function(p)
        local da = a(p)
        local db = -b(p)
        local h = math.max(0.0, math.min(1.0, 0.5 - 0.5*(db+da)/k))
        return (1.0-h)*da + h*db + k*h*(1.0-h)
    end
end

-------------------------------------------------
-- EKSEMPEL: ASTEROIDE + SPLIT
-------------------------------------------------

-- Simpel "bulky" asteroide uden noise (noise kan tilføjes senere)
function sdf.asteroid(center, radius)
    return sdf.sphere(center, radius)
end

-- Split meteorit i to via plan
function sdf.split_in_two(baseSDF, hitPoint, hitNormal)
    local splitPlane = sdf.plane(hitPoint, hitNormal)

    local left  = sdf.intersect(baseSDF,  splitPlane)
    local right = sdf.intersect(baseSDF,  sdf.plane(hitPoint, {x=-hitNormal.x, y=-hitNormal.y, z=-hitNormal.z}))

    return left, right
end

return sdf
```

👉 **Hvordan bruger du den?**

* I LÖVR: du skal raymarch i shaderen og lave SDF i GLSL (se næste sektion), men denne Lua-kode kan:

  * beskrive den samme logik til CPU (TSDF sampling, debug)
  * bruges i værktøjer, editorer, pre-computation osv.
* I LÖVE 2D: du kan lave 2.5D / fake 3D ved at sample SDF langs stråler i Lua (til test) eller kun til fysik/logik.

---

## 2️⃣ GLSL SDF raymarch shader (meteorit + split)

Her er en *minimal* fragment shader, der:

* Raymarcher en SDF-scene
* Har en asteroide
* Har en split-plane kontrolleret via uniforms
* Gør det nemt at slå split til/fra

> Noter:
> • Det er “plain” GLSL; LÖVR bruger GLSL 3.30+ (tilpas `#version` efter behov).
> • Du kan senere tilføje noise/fbm for mere organisk asteroide.

```glsl
#version 330

out vec4 fragColor;

uniform vec2  u_resolution;
uniform float u_time;

uniform vec3  u_camPos;
uniform mat3  u_camRot;

uniform vec3  u_splitPoint;
uniform vec3  u_splitNormal;
uniform int   u_splitEnabled; // 0 = ingen split, 1 = venstre halvdel, 2 = højre

//--------------------------------------------------
// SDF PRIMITIVER
//--------------------------------------------------

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdPlane(vec3 p, vec3 pointOnPlane, vec3 normal) {
    normal = normalize(normal);
    return dot(p - pointOnPlane, normal);
}

//--------------------------------------------------
// CSG OPERATIONER
//--------------------------------------------------

float opUnion(float d1, float d2) {
    return min(d1, d2);
}

float opIntersect(float d1, float d2) {
    return max(d1, d2);
}

float opSubtract(float d1, float d2) {
    return max(d1, -d2);
}

//--------------------------------------------------
// SCENE SDF
//--------------------------------------------------

float asteroidBase(vec3 p) {
    // Center ved origo, radius = 1.0
    return sdSphere(p, 1.0);
}

float sceneSDF(vec3 p) {
    float d = asteroidBase(p);

    if (u_splitEnabled != 0) {
        float planeD = sdPlane(p, u_splitPoint, u_splitNormal);
        if (u_splitEnabled == 1) {
            // "Venstre" halvdel
            d = opIntersect(d, planeD);
        } else if (u_splitEnabled == 2) {
            // "Højre" halvdel
            d = opIntersect(d, -planeD);
        }
    }

    return d;
}

//--------------------------------------------------
// RAYMARCH
//--------------------------------------------------

vec3 calcNormal(vec3 p) {
    float eps = 0.0005;
    vec2 h = vec2(eps, 0.0);
    float d = sceneSDF(p);
    vec3 n = vec3(
        sceneSDF(p + vec3(h.x, h.y, h.y)) - d,
        sceneSDF(p + vec3(h.y, h.x, h.y)) - d,
        sceneSDF(p + vec3(h.y, h.y, h.x)) - d
    );
    return normalize(n);
}

bool raymarch(vec3 ro, vec3 rd, out vec3 hitPos, out vec3 hitNormal, out int steps) {
    float t = 0.0;
    const float MAX_DIST = 50.0;
    const int   MAX_STEPS = 128;
    const float SURF_EPS = 0.0005;

    for (int i = 0; i < MAX_STEPS; ++i) {
        vec3 p = ro + rd * t;
        float d = sceneSDF(p);
        if (d < SURF_EPS) {
            hitPos = p;
            hitNormal = calcNormal(p);
            steps = i;
            return true;
        }
        t += d;
        if (t > MAX_DIST) break;
    }
    steps = MAX_STEPS;
    return false;
}

//--------------------------------------------------
// MAIN
//--------------------------------------------------

void main() {
    vec2 uv = (gl_FragCoord.xy / u_resolution) * 2.0 - 1.0;
    uv.x *= u_resolution.x / u_resolution.y;

    vec3 ro = u_camPos;
    vec3 rd = normalize(u_camRot * vec3(uv, -1.5));

    vec3 hitPos, hitNormal;
    int steps;
    if (raymarch(ro, rd, hitPos, hitNormal, steps)) {
        // Simpel lys
        vec3 lightDir = normalize(vec3(0.5, 1.0, -0.3));
        float diff = max(dot(hitNormal, lightDir), 0.0);

        vec3 baseColor = vec3(0.6, 0.55, 0.5);
        vec3 col = baseColor * (0.2 + 0.8 * diff);

        fragColor = vec4(col, 1.0);
    } else {
        // Baggrund
        vec3 bg = vec3(0.01, 0.01, 0.03);
        fragColor = vec4(bg, 1.0);
    }
}
```

👉 Din “split” i runtime:

* Når railgun rammer, sæt `u_splitPoint` til impact-punkt i verdenskoordinater.
* Sæt `u_splitNormal` til normal i impact-punktet.
* Tegn først med `u_splitEnabled = 1` → venstre halvdel (asteroid A)
* Tegn derefter med `u_splitEnabled = 2` → højre halvdel (asteroid B)

I LÖVR kan du have to draw-calls med forskellig uniform for `u_splitEnabled` og hver sin fysik-body.

---

## 3️⃣ AxiumForge JDA/JDW SDF-asteroide

Her er et forslag til **JDA asset** og et lille **JDW world-uddrag**, så det passer ind i din “alt er data” filosofi.

### 🔹 `asteroid.jda.json`

```json
{
  "jda_version": "0.1",
  "type": "sdf_asset",
  "id": "asteroid_basic_v0",
  "category": "asteroid",
  "sdf": {
    "space": "world",
    "root": {
      "node_type": "primitive",
      "primitive": "sphere",
      "params": {
        "center": [0.0, 0.0, 0.0],
        "radius": 1.0
      }
    },
    "modifiers": [
      {
        "node_type": "noise_mod",
        "noise_type": "fbm",
        "amplitude": 0.2,
        "frequency": 3.0,
        "octaves": 4,
        "operation": "add" 
      }
    ]
  },
  "csg": {
    "supports_split": true,
    "split_modes": [
      {
        "id": "plane",
        "type": "plane",
        "params_schema": {
          "point": [0.0, 0.0, 0.0],
          "normal": [0.0, 1.0, 0.0]
        }
      }
    ]
  },
  "physics": {
    "density": 2700.0,
    "tsdf": {
      "resolution": [32, 32, 32],
      "truncation_distance": 0.15,
      "storage": "float32"
    },
    "default_collider": {
      "type": "sphere",
      "radius": 1.0
    }
  },
  "render": {
    "shader": "sdf_asteroid_default",
    "material": {
      "albedo": [0.6, 0.55, 0.5],
      "metallic": 0.1,
      "roughness": 0.8
    }
  },
  "metadata": {
    "author": "Lars/AxiumForge",
    "description": "Basic SDF asteroid, sphere+noise, TSDF-backed physics.",
    "tags": ["sdf", "asteroid", "destructible"]
  }
}
```

### 🔹 JDW world-udsnit med én asteroide

```json
{
  "jdw_version": "0.1",
  "world_id": "asteroids_sdf_demo",
  "entities": [
    {
      "id": "asteroid_001",
      "asset_ref": "asteroid_basic_v0",
      "transform": {
        "position": [10.0, 0.0, 0.0],
        "rotation_euler": [0.0, 0.0, 0.0],
        "scale": [1.0, 1.0, 1.0]
      },
      "physics_state": {
        "linear_velocity": [-3.0, 0.1, 0.0],
        "angular_velocity": [0.0, 0.3, 0.0],
        "dynamic": true
      },
      "destruction": {
        "destructible": true,
        "split_strategy": "csf_split_plane_runtime",
        "min_fragment_mass": 0.1
      }
    }
  ]
}
```

Når railgun rammer `asteroid_001`, laver din game-kode:

1. Markér dette entity som “destroyed”.
2. Spawn **to nye entities** i JDW runtime-repræsentationen:

   * `asteroid_001a` med `split_side: "left"`
   * `asteroid_001b` med `split_side: "right"`
3. Begge refererer stadig `asteroid_basic_v0`, men har ekstra parametre (split point/normal, side).

---

## 4️⃣ TSDF-baseret fysik og masse efter split

TSDF-griden er din bro mellem SDF-geometri og fysik (masse, inertimoment mm.).
Basal idé:

* Du har en SDF-funktion `f(p)` (asteroiden).
* Du evaluerer den på et 3D-grid indenfor en bounding box (TSDF).
* Mass ≈ antal voxels med `f(p) < 0` × voxelVolume × density.
* Når du splitter, bruger du nye SDF’er (`f_left`, `f_right`).

### 🔹 Simplificeret Lua-pseudokode

```lua
local sdf = require("sdf")  -- modulet fra før

-- discretiser SDF til TSDF + beregn masse
local function computeMassFromSDF(sdfFunc, boundsMin, boundsMax, res, density)
    local nx, ny, nz = res[1], res[2], res[3]
    local dx = (boundsMax.x - boundsMin.x) / nx
    local dy = (boundsMax.y - boundsMin.y) / ny
    local dz = (boundsMax.z - boundsMin.z) / nz
    local voxelVolume = dx * dy * dz

    local insideCount = 0

    for iz = 0, nz-1 do
        local z = boundsMin.z + (iz + 0.5) * dz
        for iy = 0, ny-1 do
            local y = boundsMin.y + (iy + 0.5) * dy
            for ix = 0, nx-1 do
                local x = boundsMin.x + (ix + 0.5) * dx
                local p = sdf.vec3(x, y, z)
                local d = sdfFunc(p)
                if d < 0.0 then
                    insideCount = insideCount + 1
                end
            end
        end
    end

    local volume = insideCount * voxelVolume
    local mass = volume * density
    return mass
end

-- Eksempel: split meteorit og lav to fysik-kroppe
local function splitAsteroidRuntime(asteroid)
    -- asteroid.sdf_func : func(p) -> distance
    -- asteroid.boundsMin/boundsMax : vec3
    -- asteroid.density
    -- asteroid.hitPoint, asteroid.hitNormal : vec3

    local base = asteroid.sdf_func

    local splitPlane = sdf.plane(asteroid.hitPoint, asteroid.hitNormal)

    local leftSDF = sdf.intersect(base,  splitPlane)
    local rightSDF = sdf.intersect(base, sdf.plane(asteroid.hitPoint,
        {x=-asteroid.hitNormal.x, y=-asteroid.hitNormal.y, z=-asteroid.hitNormal.z}))

    local res = {32, 32, 32}
    local leftMass  = computeMassFromSDF(leftSDF,  asteroid.boundsMin, asteroid.boundsMax, res, asteroid.density)
    local rightMass = computeMassFromSDF(rightSDF, asteroid.boundsMin, asteroid.boundsMax, res, asteroid.density)

    -- Fordel momentum efter masser (simpel 1D langs normalen)
    local totalMass = leftMass + rightMass
    local v = asteroid.linear_velocity
    local n = asteroid.hitNormal
    local vAlongN = sdf.dot(v, n)

    local impulse = vAlongN * totalMass
    local leftVel  = { x = v.x, y = v.y, z = v.z }
    local rightVel = { x = v.x, y = v.y, z = v.z }

    leftVel.x  = leftVel.x  - n.x * (impulse * (rightMass / totalMass))
    leftVel.y  = leftVel.y  - n.y * (impulse * (rightMass / totalMass))
    leftVel.z  = leftVel.z  - n.z * (impulse * (rightMass / totalMass))

    rightVel.x = rightVel.x + n.x * (impulse * (leftMass  / totalMass))
    rightVel.y = rightVel.y + n.y * (impulse * (leftMass  / totalMass))
    rightVel.z = rightVel.z + n.z * (impulse * (leftMass  / totalMass))

    -- Her ville du i LÖVR:
    -- 1) slette gammel rigid body
    -- 2) oprette to nye rigid bodies med masserne leftMass/rightMass
    -- 3) give dem startposition omkring hitPoint + lille offset langs normalen
    -- 4) sætte deres linear_velocity til leftVel/rightVel
    -- 5) give shaderen de to split-sider (u_splitEnabled = 1/2) per draw-call

    return {
        left = {
            sdf_func = leftSDF,
            mass = leftMass,
            velocity = leftVel
        },
        right = {
            sdf_func = rightSDF,
            mass = rightMass,
            velocity = rightVel
        }
    }
end
```

I praksis kan du:

* Til **fysikmotoren (LÖVR/Bullet)**:

  * starte med simple sphere/box colliders (performance)
  * senere lave *approximate convex hulls* baseret på TSDF (advanceret trin).

---

## Hvad du har nu 🔧

* ✅ **CSG-toolbox i Lua** → kan bruges til editor, værktøjer, runtime TSDF osv.
* ✅ **GLSL SDF-shader** → med meteorit + split-logik klar til LÖVR.
* ✅ **AxiumForge JDA/JDW skema** til SDF-asteroide + destruktion.
* ✅ **TSDF-baseret fysik-stub** → masse efter split, simpel momentumfordeling.

Hvis du vil, kan vi i næste skridt:

* Binde det *helt konkret* til **LÖVR projektstruktur** (main.lua, shader load, uniforms)
* Eller lave en **AxiumForge “SDF-Destruction v0.1” spec** som du kan give direkte til Claude/GPT-Coder.
