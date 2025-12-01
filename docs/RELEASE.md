# Release Guide (v0 Baseline)

This project ships releases from Git tags (`v*`) via GitHub Actions. The `release.yml` workflow builds platform bundles and publishes them to GitHub Releases automatically. It also runs on pushes to `main` (helpful for validating packaging) and can be triggered manually via “Run workflow”. Branch builds are labeled `main-<shortsha>` to avoid invalid file names, and the publish step only runs on tags (branch builds stop after artifact upload). The public release name is **AsteroidDefence2D** (artifact names follow that prefix for future tags).

## How to Cut a Release
1. Bump version/tag locally, for example `v0.1.0`.
2. Push the tag: `git push origin v0.1.0`.
3. The workflow creates artifacts:
- `AsteroidDefence2D-<version>.love` (source bundle)
- `AsteroidDefence2D-windows-<version>.zip` (fused `.exe` + DLLs)
- `AsteroidDefence2D-macOS-<version>.zip` (`AsteroidDefence2D.app`)
- `AsteroidDefence2D-linux-<version>.AppImage` (fused runtime)
4. The release is published on GitHub with all artifacts attached.

## Release Notes Template (include in GitHub Release body)
- **Downloads:** Linux AppImage (`AsteroidDefence2D-linux-<ver>.AppImage`), Windows ZIP (`AsteroidDefence2D-windows-<ver>.zip`), macOS ZIP (`AsteroidDefence2D-macOS-<ver>.zip`), and `.love`.
- **Windows:** unzip, run `AsteroidDefence2D.exe` (allow SmartScreen).
- **macOS:** unzip, move `AsteroidDefence2D.app` to Applications; first launch may need right-click → Open (unsigned).
- **Linux:** `chmod +x AsteroidDefence2D-linux-<ver>.AppImage && ./AsteroidDefence2D-linux-<ver>.AppImage`. If FUSE2 is unavailable, use no-install fallback: `./AsteroidDefence2D-linux-<ver>.AppImage --appimage-extract` then `./squashfs-root/AppRun`.
- **.love:** run with an installed LÖVE 11.5 runtime (`love AsteroidDefence2D-<ver>.love`).

## Local Packaging (optional)
- Build .love:  
  `zip -9 -r build/AxiumForge-<version>.love . -x ".git*" "build/*" "screenshots/*" "*.love" ".github/*"`
- Windows fused exe (requires Windows runtime unpacked in `love/`):  
  `copy /b love.exe+build\AxiumForge-<version>.love AxiumForge.exe`
- macOS app (requires official `love.app`):  
  `cp build/AxiumForge-<version>.love AxiumForge.app/Contents/Resources/game.love`
- Linux AppImage (using official runtime):  
  `cat love-11.5-x86_64.AppImage build/AxiumForge-<version>.love > AxiumForge.AppImage && chmod +x AxiumForge.AppImage`

## Web Target (manual)
Web builds are not automated. If needed, use [love.js](https://github.com/Davidobot/love.js) with Emscripten: compile LÖVE to WebAssembly, drop the `.love` file into the exported `game.data`, and host the generated HTML/JS. Add a future GitHub Action step once a stable love.js pipeline is chosen.
