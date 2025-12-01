# Release Guide (v0 Baseline)

This project ships releases from Git tags (`v*`) via GitHub Actions. The `release.yml` workflow builds platform bundles and publishes them to GitHub Releases automatically. It also runs on pushes to `main` (helpful for validating packaging) and can be triggered manually via “Run workflow”. Branch builds are labeled `main-<shortsha>` to avoid invalid file names.

## How to Cut a Release
1. Bump version/tag locally, for example `v0.1.0`.
2. Push the tag: `git push origin v0.1.0`.
3. The workflow creates artifacts:
   - `AxiumForge-<version>.love` (source bundle)
   - `AxiumForge-windows-<version>.zip` (fused `.exe` + DLLs)
   - `AxiumForge-macOS-<version>.zip` (`AxiumForge.app`)
   - `AxiumForge-linux-<version>.AppImage` (fused runtime)
4. The release is published on GitHub with all artifacts attached.

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
