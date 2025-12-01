
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
* Stil: "Glow vector look" kombineret med **3D‑agtig, virkelighedsnær struktur** – meteorer og rumskib skal ligne fysiske objekter med volumen, overfladestruktur og lys/skygge.

---

## 2. Tekniske rammer

### 2A. Display & variabel viewport

* Spillet skal være **opløsningsuafhængigt** og fungere på både små mobiler/Steam Deck‑størrelse og store 55" skærme.
* Al logik og rendering designes efter en **virtuel basis‑opløsning** (f.eks. 1920x1080), men:

  * Den faktiske **viewport** læses via `love.graphics.getWidth()/getHeight()`.
  * SDF‑tegning og UI skaleres proportionalt, så spillet ser skarpt ud uanset skærmstørrelse.
* SDF‑grafik gør det muligt at gengive objekter **knivskarpt i højere opløsninger** uden ekstra assets.
* Mål: understøt opløsninger op til ca. **2K (fx 2560x1440)** som primær high‑end target.

### Fullscreen‑system (krav)

* Spillet skal køre i **ægte fullscreen som standard**.
* Ved opstart skal spillet:

  * Tjekke spillerens monitor‑opløsning.
  * Vælge den **nærmeste understøttede opløsning op til max 2K**.
  * Automatisk opskalere rendering uden forvrængning.
* **Vinduestilstand** skal stadig være tilgængelig, men:

  * Fullscreen er **det foretrukne** og standard.
  * UI skal auto‑repositioneres.
  * SDF‑grafik skal forblive skarp uden artefakter.

### DPI & ultrawide understøttelse

* Systemet skal håndtere **høj DPI** korrekt ved at multiplicere skaleringsfaktorer efter monitorens DPI.

* Ultrawide (21:9, 32:9) håndteres via:

  * Let letterboxing, eller
  * Udvidelse af baggrunds‑parallax, **uden at gameplay feltet deformeres**.

* Spillet skal være **opløsningsuafhængigt** og fungere på både små mobiler/Steam Deck‑størrelse og store 55" skærme.

* Al logik og rendering designes efter en **virtuel basis‑opløsning** (f.eks. 1920x1080), men:

  * Den faktiske **viewport** læses via `love.graphics.getWidth()/getHeight()`.
  * SDF‑tegning og UI skaleres proportionalt, så spillet ser skarpt ud uanset skærmstørrelse.

* SDF‑grafik gør det muligt at gengive objekter **knivskarpt i højere opløsninger** uden ekstra assets.

* Mål: understøt opløsninger op til ca. **2K (fx 2560x1440)** som primær high‑end target.

* **Fullscreen‑understøttelse er et krav**:

  * Spillet skal kunne køre i **ægte fullscreen** og automatisk vælge den nærmeste passende opløsning op til max 2K.
  * Vinduestilstand skal stadig eksistere, men **fullscreen er standard og foretrukket**.
  * UI og SDF‑grafik skal re‑scale korrekt i fullscreen uden tab af skarphed eller forhold.

* Spillet skal være **opløsningsuafhængigt** og fungere på både små mobiler/Steam Deck‑størrelse og store 55" skærme.

* Al logik og rendering designes efter en **virtuel basis‑opløsning** (f.eks. 1920x1080 eller tilsvarende), men:

  * Den faktiske **viewport** læses via `love.graphics.getWidth()/getHeight()`.
  * SDF‑tegning og UI skaleres proportionalt, så spillet ser skarpt ud uanset skærmstørrelse.

* SDF‑grafik gør det muligt at gengive objekter **knivskarpt i højere opløsninger** uden ekstra assets.

* Mål: understøt opløsninger op til ca. **2K (fx 2560x1440)** som primær high‑end target.

  * På endnu større skærme kan spillet køre i vindue/letterboxed eller skaleres op.

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

* **Meteor-flækning er en central del af projektet og SKAL implementeres i MVP.**
* Når meteoren rammes af railgun eller en anden meteorit:

  * Den **splittes i realtid** i **2–3 mindre meteorer**.
  * Hver ny meteorit arver den oprindelige SDF‑forms karakter, men:

    * Skaleres ned (fx 40–60% af radius).
    * Får nye offset‑primitiver for at simulere uregelmæssigt brud.
    * Får let varieret retning og hastighed for fysisk troværdig spredning.
  * Fragmenteringen skal være **visuelt lækker**, med:

    * små glødpartikler ved bruddet,
    * kortvarig lysflare,
    * forskydning af overflade‑støj for at markere brud.
* Senere iterationer kan udvide dette til fuld TSDF‑styret volumetrisk flækning.

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

## 5A. Præcis scenebeskrivelse (final 2025 SDF vision)

Hele spillets visuelle opsætning skal gengive en **2025-version af Asteroids** med:

* **SDF‑renderet rumscene**,
* **semi‑realistisk 3D‑agtig overfladebehandling**,
* **fysisk lys** og
* **ikonisk, genkendelig solsystem-stemning**.

### Kamera / Viewport

* Kameraet ser scenen **15–20° skråt ovenfra**, som om spilleren befinder sig i et større rumskib i kredsløb om Jorden.
* Viewporten centreres omkring *spilområdet*, mens baggrunden er tonet ned for ikke at stjæle fokus.

### Baggrundslag (dybder og parallax)

Scenen består af disse lag (fra fjernest til nærmest):

1. **Stjernefelt (dybest lag)**

   * SDF-genererede stjerner i tre skalalag: tiny (mikrostjerner), medium og få store.
   * Parallaxvirkning: næsten ingen bevægelse yderst → giver dybde.
   * Svag galaktisk tåge (støjgradient), kølige farver.

2. **Fjernt solsystem (ikonisk komposition)**

   * **Solen er placeret lavt i baggrunden**, lidt mod venstre eller højre, afhængigt af balance.
   * Solen har **SDF-baseret hvirvlende overflade** (turbulent støj + radial emission), tonet ned i intensitet så gameplay dominerer.
   * 2–3 synlige planeter i karakteristiske farvemønstre:

     * Jupiters båndede atmosfære (billboard-lignende SDF-mønster).
     * Saturns ringe (SDF‑ring + transparent alpha‑falloff).
     * Mars-lignende rødlig planet.
   * Planeterne er betydeligt større end meteorerne, men **placeret langt væk**, og tonet ned (30–40% lysstyrke) for ikke at fange øjet for meget.
   * Langsom orbital animation (meget lav hastighed).

3. **Jorden (midter‑baggrund, vigtig reference)**

   * Jorden ses som stor kugleformet SDF-planet nederst i billedet, ofte kun øvre 20–30% af dens kugle synlig.
   * Overfladen bruger SDF‑teksturerede kontinenter + skyer (procedural noise overlay).
   * Terminator-linje (dag/nat) giver realistisk 3D-kuglefornemmelse.
   * Jorden er tonet ned, men skal være tydeligt genkendelig.

### Midterlag: Spilområdet

Dette er der hvor gameplay foregår.

* **Meteorer** med høj detaljegrad: SDF‑overfladebuler, revner, kratere, støjlag.
* **3D‑agtig shading**:

  * Solens lysretning castes på meteor-overfladen via SDF-gradient.
  * Rim‑light bagfra, diskret glow rundt om konturen.
* Fragmentering skal se fysisk ud: stykker skyder af i let varierende retninger.

### Forgrund / skib

* Rumskibet tegnes som flere SDF‑lag:

  * Skrog, paneler, cockpit, lys.
  * Hårde highlights → metal look.
  * Små udbrændinger ved thrust.
* Railgun-skud er en **lysstribe** eller instant‑beam, med let dispersion og fade.

### Toning / farvebalancing

* Baggrund = 30–50% lysstyrke.
* Spilobjekter = fuld lysstyrke + skarpe konturer.
* Resultat: Baggrunden føles realistisk og episk, men distraherer ikke.

---

## 5. Visuel stil

### Overordnet

* 2D‑rendering med **3D‑lignende lys og skygge**.
* Brug SDF‑data til at udlede normals (eller pseudo‑normals) til simple lysberegninger, så objekter får volumen.

### Solsystem

* Baggrund består af et **realistisk solsystem set fra et rumskib**, vinklet **15–20° skråt ovenfra** (perspektivillusion i 2D).
* SDF‑planeter i flere parallax‑lag (forgrund → mellemgrund → baggrund).
* Planeter har diskret terminator (dag/nat‑grænse) så de fremstår som ægte 3D‑kugler.
* Solen giver global lysretning, som påvirker meteorer og skib (pseudo‑3D shading).

### Stjernebaggrund

* Realistisk dyb stjernehimmel som i referencebillederne.
* Flere lag af SDF‑genererede stjerner (tiny circles / noise field) med langsom parallax.
* Kan suppleres med svag galaktisk tåge (procedural gradient/noise) for rumsdybde.
* SDF‑planeter i baggrundslag.
* Langsom orbit og farvegradienter.
* Diskret terminator (dag/nat‑grænse) via lysretning, så planeter ser kugleformede ud.

### Meteorer

* Glow outlines, crater‑detaljer som små ekstra primitiver.
* Overfladestruktur via støj (f.eks. flere overlappende SDF‑buler) for at give sten/metal‑look.
* Pseudo‑3D shading: lysretning defineres globalt, og intensitet beregnes ud fra SDF‑gradient (eller approximativ vektor), så meteoren ligner en 3D‑klippe.

### Rumskib

* Består af flere SDF‑lag (krop, cockpit, paneler) med forskellig reflektivitet.
* Lysglimt/highlights langs kanter, så det ligner et fysisk 3D‑objekt set skråt ovenfra.

### UI

* Minimalistisk: score, liv/shields, antal meteorer.

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

## 9. Billedreference

Alle relevante referencebilleder til solsystem, meteorer, rumskib og generel 3D‑agtig realisme bliver vedlagt til AI‑coderen som bilag, så visuel stil, overfladestruktur og lysforståelse kan følges præcist.

## 10. Outputkrav

* Kørbart LÖVE projekt.
* README.md med instruktioner.
* TODO.md med fremtidige trin.
* Koden skal være klar til iteration.
