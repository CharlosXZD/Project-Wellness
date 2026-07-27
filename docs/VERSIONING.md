# Versioning & Changelog — Project Wellness

How every release gets numbered and recorded, and why — read this before finishing any change that a friend running the app would notice.

**Hard rule: every user-visible change ships with a version bump and a changelog entry, in the same turn as the code change.** This app isn't distributed through an app store — the user builds an APK and sends it straight to friends. A version number and a changelog are the *only* way anyone (including future you) can tell what a given build contains or whether they're behind. Don't treat this as optional cleanup to do "at the end" — if the work is done and the version wasn't bumped, the work isn't done.

---

## 1. The three numbers: X.Y.Z

Confirmed with the user (2026-07-17): this is **not** plain semver-by-convention, it's a specific, deliberate scheme.

| Position | Meaning | Example |
|---|---|---|
| **X** (major) | A structural/architectural change — not just a bigger feature, but a change to *how something fundamentally works*. Rare. | `2.0.0`: moved all in-progress-workout state out of the screen's own widget and into a repository so it survives navigating away — a rearchitecture, not a bolt-on. |
| **Y** (minor) | A new feature or capability the user didn't have before. | `1.6.0`: baseline sets/reps/weight step when creating a workout. `1.9.0`: unified medal exercise families. |
| **Z** (patch) | A fix to something that was already there and broken, or a small visual/behavioral correction — no new capability. | `1.5.1`: fixed inconsistent weight decimals and an Imperial-unit display bug. `2.0.1`: fixed a crash, fixed unresponsive buttons, fixed cramped stepper layout. |

The **build number** (`+N` after the semver part) increments by exactly 1 on *every* release regardless of which of X/Y/Z moved — it's a simple, monotonically increasing counter so two builds can always be ordered even if someone only glances at the `+N`.

## 2. Classify the work yourself — don't just take the user's label

The user will sometimes describe a batch of requests as "bug fixes" when some of them are actually new capabilities. **Before bumping the version, classify each item in the batch against the X/Y/Z table above, independently of how the user framed the request.** If a batch mixes real bugs with new functionality:

- Call it out plainly ("a couple of these are actually new features, not fixes — I'll ship them as their own minor bump").
- Ship the actual bug fixes as one Z release.
- Ship each distinguishable new feature (or a coherent group of related ones) as its own Y release, or bundle related features into one Y if they're clearly one unit of work.
- Reserve X for something that changes an existing mechanism's shape, not just what it does — ask yourself "did I have to restructure how existing code holds state/ownership to build this, or did I mostly add new files/branches alongside what was already there?" The former is X, the latter is Y even if it's a big Y.
- It's fine for a Y release to also absorb one or two small, incidental Z-level fixes discovered in the same pass (see `2.1.0`: one new feature plus two small bug fixes, all one minor bump) — the thing to avoid is burying a *whole batch* of real, independent bugs under one feature's version number just because they were requested in the same message.

If a single work session produces several logically distinct pieces, **bump and changelog after each one**, in order, rather than batching everything into one version at the end — that's what every release in this project's history so far has done (e.g. one session produced `1.5.1` → `1.6.0` → `1.7.0` → `1.8.0` → `1.9.0` → `2.0.0` as six separate, sequential bumps).

## 3. The mechanical steps, per release

1. Implement the change.
2. `flutter analyze` — must be clean before moving on.
3. `flutter test` — must be clean before moving on.
4. Bump `pubspec.yaml`'s `version:` line — both the semver part (per §1) and `+N` (always `+1` from whatever it was).
5. Add a new section to the **top** of `CHANGELOG.md` (reverse-chronological, newest first): `## X.Y.Z` followed by a bullet list of what shipped, written for the person receiving the APK, not for a future engineer — plain language, no file paths, no internal class names. Compare good vs. bad:
   - Good: *"Fixed weight steppers occasionally drifting to noisy values like '5.00000004' after repeated +/- taps in Imperial."*
   - Bad: *"Applied `Units.roundStorage` to `ActiveWorkoutRepository.adjustWeight`."*
6. For an X (major) bump specifically, add one line explicitly noting *why* it's major (see the `2.0.0` entry in `CHANGELOG.md` for the pattern) — the reasoning doesn't speak for itself the way a Y or Z bump's user-facing description does.

## 4. What doesn't need a bump

Pure internal refactors with zero user-visible effect (renaming a private class, moving a widget to a shared file, adding a code comment) don't need a version bump or changelog entry on their own — but if they're a side effect of a change that *does* need one, they just ride along in that same bump, unmentioned in the changelog.

## 5. Related conventions

- This is a mobile-only app (iOS/Android) despite `macos`/`windows`/`linux` folders existing in the repo from `flutter create` — "release" always means a new APK/IPA, never a web deploy.
- The app's local SQLite schema has its own independent version counter (`DatabaseHelper`'s `version:` in `lib/core/db/database_helper.dart`, currently well past 12) — bumping *that* is about a migration existing, and is unrelated to whether the app's own X.Y.Z moves. Plenty of Y/Z releases won't touch it; some will.
- No git repository exists for this project yet (the user will set one up later) — there's no commit/tag step to this process today, just the two files above.
