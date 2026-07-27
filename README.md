# Project Wellness

A personal nutrition + training tracker built with Flutter — calorie/macro logging (manual entry, barcode scanning, label OCR), workout logging with splits/templates, body-weight and nutrition trend charts, medals, and an experimental "Body Rank" per-muscle progress diagram.

This is a **mobile-only app (iOS/Android)** — the `macos`/`windows`/`linux` folders exist only because `flutter create` generates them by default; there's no desktop or web release. It isn't distributed through an app store: builds are shared directly as an APK/IPA to friends and family.

**Local-first, no backend.** There's no server and no account system — everything lives in an on-device SQLite database. The only way data ever leaves the device is the manual export/share flow described in [`docs/SHARING_SYSTEM.md`](docs/SHARING_SYSTEM.md) (sharing a workout, a recipe, a custom exercise, or a full local backup as a copy-paste code or file).

## Getting started

Standard Flutter workflow:

```bash
flutter pub get
flutter run
```

Requires a configured iOS/Android toolchain (Xcode / Android SDK). See [flutter.dev](https://docs.flutter.dev/) for environment setup if you're new to Flutter.

Before committing any change: `flutter analyze` and `flutter test` must both be clean.

## Project docs

- [`CHANGELOG.md`](CHANGELOG.md) — the full version history, newest release first. This is the authoritative source of "what shipped when" — see it for the complete list of every release.
- [`docs/VERSIONING.md`](docs/VERSIONING.md) — how version numbers and changelog entries are decided (this isn't plain semver-by-convention; read this before bumping the version).
- [`docs/SHARING_SYSTEM.md`](docs/SHARING_SYSTEM.md) — how the local share-code system works (workouts, recipes, custom exercises, full backups) and how to extend it to a new feature.
- [`docs/ICON_REGISTRY.md`](docs/ICON_REGISTRY.md) — icon coverage for workout/exercise categories.
- [`docs/NUTRITION_ICON_REGISTRY.md`](docs/NUTRITION_ICON_REGISTRY.md) — icon coverage for food categories.
- [`EXERCISE_VIDEO_REGISTRY.md`](EXERCISE_VIDEO_REGISTRY.md) — sourcing notes for the built-in exercise library's tutorial video links.

## Current version

See the top entry of [`CHANGELOG.md`](CHANGELOG.md) for the latest release notes, and `version:` in [`pubspec.yaml`](pubspec.yaml) for the exact build number.
