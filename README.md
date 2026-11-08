# Hippocampus

A native macOS menu bar app that keeps your latest 30 screenshots ready to preview, copy, or drag into another app. Screenshot history is stored locally.

## Download

[Download Hippocampus 1.1.0 for Apple Silicon](https://github.com/DavidJiang1121/Hippocampus/releases/tag/v1.1.0). Requires macOS 13 or later. Unzip the download and move `Hippocampus.app` to Applications. This build uses ad-hoc signing. macOS may ask you to verify the app on first launch.

[使用说明](使用说明.md) · [安装与编译](安装与编译.md)

## Build from source

`bash build.sh [output-directory] [build-directory]` builds and ad-hoc signs the app, generates the original hippocampal ribbon icon, and runs tests. Requires the Xcode macOS SDK, Swift, and Python 3; no packages or network access are needed.

- `Sources/Library.swift`: serial, atomic history persistence; 30-item FIFO retention; canonical image conversion; cross-channel coalescing.
- `Sources/Monitor.swift`: screenshot folder polling, scoped screenshot thumbnail cache discovery, optional clipboard image collection, export and settings.
- `Sources/Views.swift`: gallery, menu bar panel, preview, settings, native Control-click and file/image drag source.
- `Sources/Icon.swift`: shared flat vector outline traced from the selected two-notch concept, used for the app icon and menu glyph.
- `Sources/main.swift`: application lifecycle, status item, windows, menus.
- `Tests`: FIFO disk limit, restart, coalescing, repeated images, invalid data, failed transaction rollback and corrupt manifest preservation.
- `InteractionTests`: both macOS Control-click event routes, preview, keyboard, accessibility, AppKit ICNS decoding, and rejection of incoming file drags in both galleries.

The app monitors Desktop and the current system screenshot location, plus one optional user-selected folder. It does not recursively search personal folders. The initial import takes at most the newest 30 matching files. File monitoring uses screenshot metadata with localized filename fallback. Clipboard capture also collects other copied images; it can be disabled. Temporary screenshot cache access is best effort, not a guaranteed capture API. No system screenshot settings are overwritten. No screen recording, Accessibility or network entitlement is required by the application.

History lives in `~/Library/Application Support/Hippocampus/Captures`. The index is committed before evicting images. Source files are never deleted. A corrupt index blocks collection and preserves existing files. File drag operations create temporary independent PNGs, so history eviction cannot invalidate a drag. Temporary drag copies older than one day are removed on the next launch.

Both gallery surfaces use an `ExportOnlyHostingView` that rejects incoming drag entry, updates, preparation and commit. There is no SwiftUI drop handler. Native thumbnail drag sources still export a copy; the explicit file-picker import remains available.

For isolated UI testing, launch a separate test bundle with `HIPPOCAMPUS_DATA_DIR` and `HIPPOCAMPUS_SCREENSHOT_DIR` in its `LSEnvironment`. `HIPPOCAMPUS_TEST_MODE=1` disables monitoring for static gallery previews. These overrides are absent from the delivered app.
