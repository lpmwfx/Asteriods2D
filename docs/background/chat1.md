Fantastisk — **railgun + SDF/TSDF-kollisioner** bliver et af de stærkeste elementer i spillet.
Railgun giver hastighed, fysik-dramatik og visuelt *impact* som er perfekt til SDF-verdenen.

Nedenfor får du:

# ✔️ 1. Railgun som gameplay–mekanik

# ✔️ 2. Railgun som SDF-effekt

# ✔️ 3. Kollisioner i SDF/TSDF (meteorer splintrer realistisk)

# ✔️ 4. Fysik-kode (LÖVE 2D / Box2D)

# ✔️ 5. “Juice”: lyd, lys, chokbølger, linsestråler

---

# 🌩️ 1. Railgun Gameplay

Railgun er **instant-hit** (ingen fysisk bullet).
Men i vores version kan vi kombinere instant-hit *og* synlig beam:

### **Railgun karakteristik**

* **0 spread** (perfekt præcision).
* **Lineært skud** gennem flere meteorer.
* **Overpenetration**: railgun stråle fortsætter gennem meteorer, reducerer deres TSDF.
* **Cooldown**: 1–3 sekunder.
* **Recoil**: lille rotation på skibet (SDF-juice).

### **Player feel**

* Tryk SPACE →

  * skibet *låser retningen* 100ms
  * energiladning “VZZZMMM”
  * stråle affyrer
  * meteorer splintrer i realtid.

---

# 🌐 2. Railgun som SDF-effekt (2D shader)

Railgun-beamen kan vises som en **glødende cylinder i 3D**, projiceret ned i 2D.

### SDF for railgun-stråle:

```
distance_to_beam = distance_to_line(point, start, end) - beam_radius
```

Color:

* midterkern: hvid-blå
* ydre glød: cyan → violet
* mix baseret på `exp(-d * k)`

### TSDF multiplicering:

Når railgun affyres, laver vi:

```
meteor.TSDF = meteor.TSDF - gauss_beam_shape
```

Dette “skærer” en kanal igennem meteorens volumetriske rum.
Hvis TSDF bliver tynd nok → meteor **splitter i dele**.

---

# ☄️ 3. SDF/TSDF-kollisioner med meteorer

Meteorer er 3D TSDF-procedurer, som fx:

* støj-moduleret ellipsoid
* crater-noise (Perlin ridges + booleans)

Når railgun rammer:

### **A) Overfladekollision**

Vi tester:

```
if TSDF(point_on_beam) < 0 → impact
```

### **B) Splintring / Fraktur**

Railgun laver en **skive** gennem TSDF’en:

```
TSDF_new = min(TSDF_old, plane_cut_function)
```

Derefter køres “connected components” pr meteoroid:

* hvis meteorens TSDF bliver opdelt i 2–5 regioner →

  * hver region bliver til **sin egen Box2D-body**
  * får impuls (shards flyver væk).

### **C) Variable metal / rock density**

Vi kan have et density-field inde i meteoren:

```
density = FBM_noise(position)
damage = energy / density
```

→ Tung kerne kræver mere energi.

---

# 💥 4. Fysik: Railgun-kollisioner i LÖVE / Box2D

Railgun er *raycast* i fysik:

```
local x1, y1 = ship.x, ship.y
local x2, y2 = ship.x + cos(angle)*10000, ship.y + sin(angle)*10000

world:rayCast(x1, y1, x2, y2, callback)
```

### Når raycast rammer meteorer

Callback:

```lua
function rayCallback(fixture, x, y, xn, yn, fraction)
    local meteor = fixture:getUserData()
    meteor:applyDamage(railgunPower, x, y, xn, yn)
    return -1   -- railgun fortsætter gennem alt
end
```

Meteor damage → reducerer TSDF internt → hvis fraktur → split.

---

# ⚡ 5. “Juice”: det der gør railgun sindssygt tilfredsstillende

### **A) Screen shake**

Når railgun affyres:

```
camera.shake( intensity = 4, duration = 0.25 )
```

### **B) Linsestråler og bloom**

Railgun trail tegnes som:

* 1 tynd kerne
* 2 brede glød-lag
* 1 linsestråle flare (animerede star spikes)

### **C) Atmosfærisk partikelstøv**

Selvom rummet er vakuum, laver vi:

* små ioniserede partikler
* blå gnister på overfladen af meteoren

### **D) Railgun lyd**

* Opladning: lav frekvens stigning (saw-wave + lowpass)
* Affyring: *bang + crack* (kort, hårdt, metallic)
* Efterglød: elektrisk knitren (white noise gennem bandpass)

---

# 🧠 6. Railgun design som del af gameplay balancen

Railgun må ikke være *for* stærk. Vi kan justere:

* **Opvarmning**: 2–3 sek burst → overheat → cooldown.
* **Energi-meter**: skyd for meget → skibet mister power til thruster en periode.
* **Ricochet meteorer**: nogle meteorer har metalplader, som reflekterer 15°.

Dette giver:

> Asteroids tempo + moderne fysik + voldsom energi + visuelt “wow”.

---

# 🔧 7. Hvis du vil, kan næste skridt være:

### ✔️ Railgun distance-funktion + shader pseudo-code

### ✔️ Meteoroid TSDF-generator (craters, noise, irregular shape)

### ✔️ Railgun damage-model + fraktur-algoritme

### ✔️ LÖVE 2D kode til railgun med raycast + visuel beam

Hvad vil du helst have vi bygger først?

