# Local Sharing System — Project Wellness

How workout/split sharing and full-data backup work, and how to reuse the same mechanism for a new feature (e.g. sharing a nutrition day, a saved snack, or a supplement stack).

**Hard rule: no cloud, no backend, no accounts.** Everything below is pure local encode/decode — a string or a `.txt` file the user hands off themselves (iMessage, WhatsApp, AirDrop, email, whatever). The app never talks to a server for any of this.

This promise is enforced past the app's own code, too: Android's `AndroidManifest.xml` sets `android:allowBackup="false"` and iOS's `AppDelegate.swift` explicitly excludes the Application Support directory from device/iCloud backup (`excludeAppDataFromDeviceBackup()`). Without those, the OS's own backup mechanisms would silently include the SQLite database in the user's Google/iCloud account by default — closing that gap is deliberate, not an oversight, so don't remove either as unnecessary config. The only sanctioned way data ever leaves the device is the manual export/share flow below — reinforced by an optional weekly "back up your data" local notification (see `lib/core/notifications/notification_service.dart`'s `scheduleBackupReminder`) that just nudges the user to run Export themselves.

---

## 1. The three layers

```
lib/core/sharing/
  share_codec.dart     generic codec — no domain knowledge, reusable for anything
  workout_share.dart    domain layer for WorkoutTemplate / WorkoutSplit
  backup_service.dart   domain layer for a full-database dump/restore
```

**`share_codec.dart`** is the only place that knows about bytes. It has exactly two functions:

- `encodePayload(Map<String, dynamic> json, String prefix)` → `jsonEncode` → `utf8.encode` → `GZipCodec().encode` → `base64Url.encode` → prefix the result. Returns one string like `PWD1.H4sIAAAAAAAA...`.
- `decodePayload(String code)` → splits on the first `.` to recover the prefix, reverses the pipeline, and returns `(prefix: String, json: Map<String, dynamic>)`. Any failure anywhere (bad base64, corrupt gzip, malformed JSON) is caught and rethrown as one `ShareCodeException` with a message that's already safe to show the user directly (`'That code looks invalid or corrupted.'`).

Nothing else in the app should touch `dart:convert`'s `base64Url`/`GZipCodec` directly for this purpose — always go through `encodePayload`/`decodePayload` so every share code in the app has the same shape and the same failure mode.

**Domain layers** (`workout_share.dart`, `backup_service.dart`) each do two things: turn a model (or set of models) into a plain `Map<String, dynamic>` (JSON-safe: strings, nums, lists, nested maps — no `DateTime`/enum objects directly), and turn that map back into real model instances. They call `encodePayload`/`decodePayload`, they never touch gzip/base64 themselves.

**UI layer** (`lib/widgets/share_code_sheet.dart`, `lib/widgets/import_code_dialog.dart`) is generic over the domain layer — it shows/copies/shares whatever string it's given, and for import it dispatches on the prefix. It doesn't know what a "template" or a "split" is beyond the `DecodedShare` sealed class described below.

---

## 2. The prefix system

Every code starts with a short version tag before the first `.`, defined in `SharePrefix` (`share_codec.dart`):

| Prefix | Meaning |
|---|---|
| `PWD1.` | a single day's `WorkoutTemplate` |
| `PWS1.` | a whole `WorkoutSplit` + its templates |
| `PWF1.` | a full local-database backup |
| `PWC1.` | a `SavedFoodCombo` (a saved snack or meal, with its ingredients if it's a recipe) |
| `PWE1.` | a `CustomExercise` (a user-created personal exercise) |

The prefix exists so a decoder can reject the wrong kind of code immediately (e.g. pasting a split code where a template was expected) and so **one paste box can handle multiple code types** — see `decodeAny()` in `workout_share.dart`, which looks at the prefix and returns a `DecodedShare` (a sealed class with `DecodedTemplateShare` / `DecodedSplitShare` / `DecodedComboShare` / `DecodedCustomExerciseShare` variants) for the UI to switch on. The trailing digit is a version number — if the payload shape ever needs to change incompatibly, bump it (`PWD2.`) rather than mutating what `PWD1.` means, so old codes floating around in someone's message history don't silently decode wrong.

---

## 3. Design decisions (the "why", so future changes don't undo them)

- **Fresh IDs on every import.** Decoding a template or split never reuses the sender's row IDs — `_templateFromJson`/`_exerciseFromJson` generate new `Uuid().v4()`s and a fresh `createdAt`. This is what makes imports safe to run repeatedly and impossible to collide with the recipient's own data.
- **Workout/split imports are additive, never destructive.** Importing a split only inserts new templates and replaces the *split record* (name/type/day list) — it never deletes the recipient's existing templates or logged sessions, even for days with the same name. Only the full-backup import (`backup_service.dart`) is destructive, and that path always requires an explicit in-app confirmation dialog before it runs (see `settings_screen.dart`) because it wipes and reinserts every table in one transaction.
- **The backup blob is opaque on purpose.** `exportBackup()` reads every table into `{'tables': {...}}` and runs it through the same `encodePayload` as the workout codes — the resulting `.txt` file is compact and not a readable SQL/JSON dump, kept consistent with the rest of the system rather than because of any real security requirement.
- **Table order matters in `backup_service.dart`.** `_tableOrder` lists parents before children (e.g. `workout_templates` before `template_exercises`) because inserts need parents to exist first (foreign keys) and deletes run in reverse (children before parents). If you add a table with a foreign key, insert it into `_tableOrder` *after* whatever it references.

---

## 4. How to reuse this for a new feature

Say you want to share a saved snack or a day of nutrition logging. The pattern is always the same:

1. **Pick a new prefix** in `SharePrefix` (`share_codec.dart`), e.g. `snack = 'PWN1.'`.
2. **Write `_xToJson` / `_xFromJson`** for the model(s) involved, in a new file (`lib/core/sharing/nutrition_share.dart`) or alongside `workout_share.dart` if it's small — map to/from plain `Map<String, dynamic>`, regenerating IDs and timestamps on the way back in, exactly like `_templateFromJson` does.
3. **Wrap them**: `encodeX()` calls `encodePayload(_xToJson(x), SharePrefix.x)`; `decodeX()` calls `decodePayload`, checks the prefix, calls `_xFromJson`.
4. **If it should share one paste box** with the existing workout codes, add a case to `decodeAny()` and a new `DecodedXShare` variant to the `DecodedShare` sealed class, then handle it in `import_code_dialog.dart`'s switch. If it's a genuinely separate flow (different screen, doesn't make sense to mix with workout imports), it's fine to give it its own small paste dialog instead — don't force unrelated features through one dispatcher just for reuse's sake.
5. **UI**: call the existing `showShareCodeSheet(context, title:, code:, shareSubject:)` from `lib/widgets/share_code_sheet.dart` — don't build a new bottom sheet, this one already does code display + native share + clipboard copy. Put the trigger for it as a small, low-emphasis text link near the relevant content (see the "Share" link under each workout card in `day_templates_screen.dart` for the visual pattern: `TextButton.icon`, small icon, `bodySmall`/`onSurfaceVariant` styling — not a prominent button).
6. **If the new data lives in its own table(s)**, also add them to `_tableOrder` in `backup_service.dart` so full backup/restore keeps covering everything — this list is not automatically derived from the schema, it has to be kept in sync by hand.

## 5. Where things are wired up today

- `lib/features/training/day_templates_screen.dart` — per-template "Share" link → `encodeTemplate` → `showShareCodeSheet`.
- `lib/features/training/training_screen.dart` — "Share my split" → `encodeSplitBundle`; "Import shared workout" → `showImportCodeDialog` (handles template, split, and combo codes).
- `lib/repositories/training_repository.dart` — `importSplitBundle()` saves an imported split + all its templates in one transaction, then reloads once (avoids N reloads for N templates).
- `lib/features/settings/settings_screen.dart` — "Export my data" (writes the backup blob to a temp file, opens the native share sheet) / "Import data" (file picker → confirmation dialog → `importBackup` → reload every repository).
- `lib/core/sharing/nutrition_share.dart` — `_comboToJson`/`_comboFromJson` for `SavedFoodCombo` (snacks and meals, including their `Ingredient` list if it's a recipe), `encodeCombo`/`decodeCombo`.
- `lib/features/nutrition/snacks_screen.dart` and `meals_screen.dart` — per-combo "Share" link (same visual pattern as the workout one) → `encodeCombo` → `showShareCodeSheet`; "Import shared snack"/"Import shared meal" → `showImportCodeDialog` (same generic paste box as workouts — it dispatches on prefix regardless of which screen opened it).
- `lib/core/sharing/workout_share.dart` — `_customExerciseToJson`/`_customExerciseFromJson` for `CustomExercise`, `encodeCustomExercise`/`decodeCustomExercise`.
- `lib/features/training/personal_exercises_screen.dart` — per-exercise "Share" link → `encodeCustomExercise` → `showShareCodeSheet`; pasted `PWE1.` codes are handled by the same `showImportCodeDialog` as everything else.

Dependencies: `share_plus` (native share sheet, text and files) and `file_picker` (pick the backup file back in) — both added to `pubspec.yaml` for this system. Everything else (`dart:convert`, `dart:io`'s `GZipCodec`, the existing `uuid` package) was already available.
