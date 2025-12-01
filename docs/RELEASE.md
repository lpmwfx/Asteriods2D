# Release Guide (v0 Baseline)

This project ships releases from Git tags (`v*`) via GitHub Actions. The `release.yml` workflow builds platform bundles and publishes them to GitHub Releases automatically. It also runs on pushes to `main` (helpful for validating packaging) and can be triggered manually via “Run workflow”. Branch builds are labeled `main-<shortsha>` to avoid invalid file names, and the publish step only runs on tags (branch builds stop after artifact upload).

## How to Cut a Release
1. Bump version/tag locally, for example `v0.1.0`.
2. Push the tag: `git push origin v0.1.0`.
3. The workflow creates artifacts:
   - `AxiumForge-<version>.love` (source bundle)
   - `AxiumForge-windows-<version>.zip` (fused `.exe` + DLLs)
   - `AxiumForge-macOS-<version>.zip` (`AxiumForge.app`)
   - `AxiumForge-linux-<version>.AppImage` (fused runtime)
4. The release is published on GitHub with all artifacts attached.

## Release Notes Template (include in GitHub Release body)
- **Downloads:** Linux AppImage (`AxiumForge-linux-<ver>.AppImage`), Windows ZIP (`AxiumForge-windows-<ver>.zip`), macOS ZIP (`AxiumForge-macOS-<ver>.zip`), and `.love`.
- **Windows:** unzip, run `AxiumForge.exe` (allow SmartScreen).
- **macOS:** unzip, move `AxiumForge.app` to Applications; first launch may need right-click → Open (unsigned).
- **Linux:** `chmod +x AxiumForge-linux-<ver>.AppImage && ./AxiumForge-linux-<ver>.AppImage`. If Fuse2 is missing, install `libfuse2` (e.g., `sudo apt install libfuse2`) or run `--appimage-extract` then `./squashfs-root/AppRun`.
- **.love:** run with an installed LÖVE 11.5 runtime (`love AxiumForge-<ver>.love`).

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
