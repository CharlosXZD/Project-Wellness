# Changelog

All notable changes to Project Wellness are recorded here, release by release.

## 2.19.0

- New 7-day activity strip at the top of the Home, Nutrition, and Training screens — a dot marks each day something was logged (food, a workout, or both on Home). Tap a day on Nutrition to see everything logged that day, or on Training to jump to that day's workout.

## 2.18.0

- New "Previously scanned" screen (Nutrition, and linked from Personal Foods' "Scan to add") — every barcode you've looked up is saved locally, so you can log it again or save it to Personal Foods without pointing the camera at it a second time.
- Scanning the same barcode twice now updates the same cached entry instead of creating a duplicate.

## 2.17.0

- Personal Exercises and Personal Foods now have "Export my library" / "Import shared library" — one code that bundles *all* your custom exercises and personal foods together, so you can send your whole library in one message instead of sharing items one at a time. Importing only adds what you don't already have (matched by name) — it never overwrites or duplicates anything already in your library.

## 2.16.0

- Creating or editing a personal exercise now lets you mark it as Timed (logs a duration, like Pilates) or Distance-based (logs duration + calories burned + distance, like Cardio) instead of the usual sets/reps — no need to misfile it under the Cardio or Pilates category just to get duration-based logging. Shared/imported custom exercises carry this setting too.

## 2.15.0

- Body Rank's diagram is now tappable — tap a muscle on the diagram, or its name in the list below, and it lights up on the body (either one highlights both) — and a card appears showing every exercise that trains it.

## 2.14.1

- Fixed several screens where content or buttons could sit under Android's gesture navigation bar (newer Android versions draw behind it by default): the label-scanner's capture button, and the Nutrition, Body Rank, Medals, Weight history, Custom split, and Add-exercise screens now all clear it properly.

## 2.14.0

- "Create new meal" (My meals' quick manual-entry button) now lets you pick Breakfast/Lunch/Dinner before saving, instead of always saving as Breakfast — the same picker that "Build a recipe" already had.
- On the My meals screen, "Create new meal" and "Build a recipe" now sit at the top, with "Tap to add to today" and your saved meals below them.

## 2.13.0

- Body Rank now has a matching female diagram — it follows the sex set in your profile automatically, no toggle needed.
- Body Rank's artwork now draws as flat color fills with the muscle outline crisply on top, instead of tinting the outline art directly — cleaner edges, no more stray color specks on the hands.

## 2.12.1

- Deleting a workout (or a single exercise from one, or a food entry) now re-checks your medals and removes any that only got unlocked because of what you just deleted — e.g. a medal earned from a test workout you didn't actually do.

## 2.12.0

- Body Rank's diagram now uses real illustrated line art instead of the original procedurally-drawn body — same 13 regions and 9-tier coloring, just properly drawn this time.

## 2.11.0

- New experimental **Body Rank** feature (off by default — enable it in Settings under "Experimental"): a front/back muscle diagram where each of 13 muscle groups climbs its own 9-tier rank ladder (Novice → Trainee → Amateur → Competent → Advanced → Elite → Master → Grandmaster → Legendary) based on how much you've actually lifted with it over time, each tier its own color on the diagram. An "Overall Rank" summarizes all 13 at a glance. Open it from a new card on the home screen once the toggle is on.

## 2.10.1

- Fixed a crash ("No Overlay widget found") that could hit whenever the floating active-workout bar showed up over another screen.
- Fixed the screen going black and needing an app restart after finishing a workout that was resumed from somewhere other than the Training screen (e.g. right after reopening the app mid-workout).
- The "added exercises" list when building a workout is now a compact row of icons instead of full-width cards, so adding several exercises no longer squeezes the search bar off the bottom of the screen.

## 2.10.0

- Split the combined "Arms" category into separate **Biceps** and **Triceps** categories, so they're browsable and suggested independently instead of lumped together — plus 10 new exercises: Barbell Preacher Curl, Incline Dumbbell Curl, Drag Curl, Cross-Body Hammer Curl, Cable Rope Hammer Curl, and 21s for Biceps; Dumbbell Tricep Kickback, JM Press, Tate Press, and Single Arm Cable Tricep Pushdown for Triceps. Every exercise has its own tutorial video.

## 2.9.0

- Medals expanded from 22 to 50 achievements, with a new bronze/silver/gold/platinum rarity shown right on each medal — a mix of first-timers, weight thresholds, and much harder platinum-tier goals.
- New "Consistency" category: streak medals (7/30/100/365 days), total-workouts-logged medals, food-logging-days medals, and two "collector" medals for unlocking half — or all — of everything else.
- New Training medals for Overhead Press and Row/Pull-Up, a "Big 3 total" (bench+squat+deadlift combined) series, single-session volume medals, and lifetime personal-record-count medals.
- New Cardio medals for half marathon, full marathon, and lifetime distance milestones.
- Logging food now checks for newly-unlocked medals too, not just finishing a workout or weighing in — you'll get the same unlock message either way.
- Unlocking a medal now also sends a "Medal unlocked!" push notification (if you've allowed notifications), so you'll see it even if the app is in the background.
- The home screen now shows your nearest upcoming medal with a small progress bar, tap it to jump straight to the Medals screen.

## 2.8.0

- Personal Foods now has a "Scan to add" option — point the camera at a barcode or nutrition label and it prefills the new-food form with the name and per-100g macros, so you don't have to type them in by hand. Review and adjust before saving, same as creating one manually.

## 2.7.0

- Added a new Forearms category with 12 exercises — Barbell/Dumbbell/Cable Wrist Curl, Barbell/Cable Reverse Wrist Curl, Behind-the-Back Barbell Wrist Curl, Zottman Curl, Barbell Finger Curl, Wrist Roller, Plate Pinch, Hand Gripper, and Dead Hang — each with its own tutorial video. Forearm work now shows up in the exercise picker, template builder, and Pull/Upper/Arms day suggestions instead of being missing entirely.

## 2.6.2

- Fixed the rebuilt label scanner (2.5.0) always reporting "Couldn't read that label" on this device — the camera's own photo format was tripping up the new OCR engine's image loader, unrelated to how well-lit or clear the label was. Photos are now converted to a format it reads reliably before scanning.

## 2.6.1

- Fixed "Precise calorie tracking" badly underestimating maintenance calories for anyone with a desk job who exercises often — e.g. a desk job + 6 days/week of moderate exercise landed on the "Exercise 1-3x/week" tier instead of "Intense exercise 6-7x/week", because the job baseline was letting a couple of sedentary hours outweigh a whole week of actual training. Exercise days/intensity now decide the tier first, with job only nudging it by at most one level on top.

## 2.6.0

- Rebuilt the Goals & BMR screen: today's target now leads with a progress bar showing how much of it you've logged so far, a new card right below it shows exactly how many calories you've eaten today and how many are left (or how far over), and "Goal" plus "Target weight" are now one grouped card instead of two separate sections.
- Reworked the activity-level scale to match the standard 6-tier table used by calculator.net's BMR calculator (Sedentary, Exercise 1-3x/week, Exercise 4-5x/week, Daily/intense 3-4x/week, Intense 6-7x/week, Very intense daily) — a finer scale than the 5-tier one used before, including at onboarding.
- "Precise calorie tracking" (the job-activity + exercise-days + intensity questionnaire) now works differently: instead of computing its own multiplier and narrowing the estimate to a ±75 kcal range, it picks the single closest tier off that same 6-tier table and shows one exact number, no range at all. This applies everywhere a target-calorie range is shown (Nutrition, Nutrition Insights, Weight history), not just this screen.

## 2.5.0

- Rebuilt the nutrition scanner from scratch. It now opens straight to a barcode scanner by default — point it at a packaged item's barcode and it looks up the calories/protein/carbs/fat straight from an open food database, no typing needed. A "Label" tab next to it switches to the old camera-scan-the-nutrition-facts mode, now running on a different, working text-recognition engine (the previous one was permanently broken on some newer phones, including the Galaxy S22 Ultra, due to an unfixable bug in Google's scanning library). If a barcode isn't found or a label still can't be read, both modes point you straight at manual entry.

## 2.4.0

- Exercises can now be reordered by dragging — during an active workout, when first picking exercises for a new workout, and on the "starting stats" screen where you set each one's baseline. Drag the handle on the left of each exercise to move it.

## 2.3.2

- Fixed the weight display still showing a decimal (e.g. "60.1") once a set's weight passed roughly 55-60 lbs on Imperial units, even after 2.2.3's display fix. The real cause wasn't display formatting — it was the weight steppers snapping the *stored* value to the nearest 0.01 kg after every tap, and a 5 lb step doesn't land evenly on that grid, so each tap nudged the true weight a hair off in the same direction. That's invisible for the first several taps but adds up past ~55-60 lbs into a visible decimal. Storage now snaps to the nearest 0.001 kg instead, fine enough that the same drift would take hundreds of taps to become visible again.

## 2.3.1

- The nutrition-label scanner's repeated failures on some newer Android phones (confirmed on a Galaxy S22 Ultra running Android 16) traced to a currently-open bug in Google's ML Kit itself — a native library ML Kit ships isn't built for the 16KB memory-page layout newer Android devices use, so every scan attempt fails to decode regardless of what this app sends it. Not fixable from this app's code (tracked upstream at github.com/googlesamples/mlkit/issues/975). The scanner now recognizes when it's stuck like this and, after a couple of failed attempts, stops suggesting "try again" and instead offers a direct "Add manually" action — use Personal Foods or manual entry to log packaged items on affected devices until Google ships a fix.

## 2.3.0

- Your in-progress workout is now saved to disk as you go, so if the app crashes or restarts unexpectedly mid-workout, it comes right back where you left off (sets, weights, reps, elapsed time, pause state) instead of being lost. Restore happens automatically on the next launch, no prompt.

## 2.2.3

- Fixed set weights during a workout occasionally showing a spurious ".0"/".x" (e.g. "72.0" instead of "72") — caused by the same floating-point noise from kg/lbs unit conversion that a previous fix already handled for the tap-to-type dialog, just not for the on-screen number itself. Weight and distance now round to a clean value before deciding whether to show a decimal, everywhere they're displayed.

## 2.2.2

- Fixed the nutrition-label scanner still failing to read every label after 2.2.1's fix, confirmed by device logs — the actual cause was ML Kit's own file-reading code crashing with a native error on every call on some devices, regardless of how complete the photo file was (2.2.1's theory was wrong; the file was fine). The scanner now decodes each photo itself and hands ML Kit the raw image directly, avoiding that broken code path entirely, with the old approach kept as a first attempt in case it still works fine on other devices.

## 2.2.1

- Fixed the nutrition-label scanner still failing to read labels after 2.2.0's fix — the real cause was `ResolutionPreset.veryHigh` photos not being fully finished encoding by the time the text reader opened them (a non-empty file isn't the same as a complete one), which crashes ML Kit's image decoder every time, not just occasionally. Each photo is now verified to actually decode before it's used, and shots are paced by that instead of a fixed guessed delay.
- Redesigned the Goals & BMR screen — today's target calories now leads as the headline number, "Goal" and "Target weight" are their own clear sections, and the BMR/activity math plus the "Precise calorie tracking" questionnaire are tucked into a collapsed "How we calculated this" section instead of competing for attention.
- The target-weight calorie estimate on that screen now accounts for your current deficit/surplus goal, not just flat maintenance — it shows what you'd actually eat once you reach that weight while keeping the same goal.

## 2.2.0

- Fixed the nutrition-label scanner crashing with a raw error dump instead of reading the label — caused by the camera occasionally handing a not-yet-finished photo to the text reader; failed frames are now skipped instead of crashing the scan, and any remaining failure shows a short message instead of a wall of text.
- Added an "Add manually" option to the recipe/meal builder and made "Add manually" always reachable from food search, not just when a search comes up empty.
- Added Personal Foods — create your own reusable food with its own calories and macros (and optional fiber/sugar/sodium), the same way personal exercises work. Manage them from Settings, or add one straight from food search.
- Nearly doubled the food search library (90 → 228 items) with more fruits, vegetables, meats, poultry, seafood, and pantry staples, and added fiber, sugar, and sodium tracking throughout — logged manually, scanned automatically off a label, or set on a personal food.
- Added an activity-level question at signup so brand-new accounts (with no workout history yet) get a more realistic starting calorie estimate instead of defaulting to Sedentary.
- Added an opt-in "Precise calorie tracking" setting (Goals & BMR) — answer a couple more questions about daily job activity and typical exercise intensity to narrow the target-calorie range from ±150 to ±75 kcal/day.
- Added a one-time nudge on the Nutrition screen if you report being very active but the app sees almost no logged workouts, pointing at Health sync as a more accurate alternative.

## 2.1.0

- Added the ability to delete a workout entirely from its edit screen (previously logged sessions of it are kept).
- Fixed chart Y-axis labels sometimes overlapping near the top instead of being evenly spaced (progress charts and the weight-history chart).
- Fixed weight steppers occasionally drifting to noisy values like "5.00000004" after repeated +/- taps in Imperial — every weight/distance adjustment now snaps to a clean value at the moment it's made, not just when displayed, so the drift can no longer accumulate.

## 2.0.1

- Fixed a crash when tapping the floating active-workout bar to jump back into the workout.
- Fixed the active workout screen not responding immediately to pause/weight/reps/set button presses, and the floating bar staying visible over the Finish button or after ending a workout — both caused by the same underlying timing bug in how the bar's visibility was tracked.
- The floating active-workout bar can now be dragged up or down to reposition it out of the way.
- Fixed the "starting stats" screen's sets/reps/weight controls looking cramped and flattened — they now match the active workout screen's layout.

## 2.0.0

- Active workouts now persist across the app — leave the workout screen to check Nutrition, another workout day, or Medals, and a floating bar shows your progress and timer, with a tap back in. Includes a pause button so stepping away doesn't inflate your workout time.
- This is a structural change to how in-progress workouts are tracked (not just a new feature), hence the major version bump.

## 1.9.0

- Medals now track exercise *families* instead of one exact exercise — Back Squat, Hack Squat, Front Squat, etc. all count toward the same squat medals, and likewise for bench press, deadlift, hip thrust, and curl/extension variants.

## 1.8.0

- Added a weight-progress chart per exercise to the post-workout summary and the workout details screen.
- The 5-4-3-2-1-GO countdown pops more, and tapping the screen 3 times skips straight to the workout.
- Unlocking a medal now shows an animated trophy pop instead of a static icon.

## 1.7.0

- Workout details screen: tap a logged exercise to fix its weight/reps or add/remove sets, or remove the exercise from that workout entirely.

## 1.6.0

- Creating a new workout now has a "starting stats" step — set sets/reps/weight per exercise (and mark arm/leg exercises unilateral) before saving, so the very first real session already has a baseline to compare against.
- Both exercise pickers now have a "Create new exercise" card right at the top, not just as a fallback when a search comes up empty.
- Tapping a workout card now starts it directly; tap the pencil icon to edit it instead.

## 1.5.1

- Fixed weight values showing inconsistently (e.g. "70" in one screen, "70.0" in another) — whole numbers now always drop the decimal everywhere.
- Fixed the workout details screen always showing "kg" even with Imperial units selected.

## 1.5.0

- Added Medals — a trophy button on the home screen (with a badge when you've got unseen unlocks) opens a Medals screen tracking first-workout, first-lift, weight-threshold, cardio-distance, and cut/bulk-completion medals, each with a progress bar toward the next tier.
- Finishing a workout now shows a banner for any medal you just unlocked.
- Logging a new body weight can also unlock a medal (e.g. completing a cut or bulk).

## 1.4.0

- Starting a saved workout now leads with a 5-4-3-2-1-GO countdown before logging begins.
- The active workout screen shows a live running timer.
- Finishing a workout now shows a summary screen — total time, and how each exercise compares to last time and to 3 months ago, with a PR badge for new bests.

## 1.3.0

- Added Personal Exercises — create your own exercise with a category, equipment/movement icon, unilateral flag, and an optional form-video link, from Settings → Personal Exercises or straight from either exercise picker.
- Personal exercises show up under a new "Personal" chip alongside the regular category chips when building a workout.
- Share a personal exercise as a code (same mechanism as sharing a workout or split) so someone else can import it.

## 1.2.0

- Added support for unilateral (single-arm/single-leg) exercises — "Single Arm Tricep Extension" and "Single Arm Overhead Tricep Extension" now log a left and a right set for each numbered set.
- Cardio exercises (Running, Cycling, Rowing Machine, etc.) now log duration, calories burned, and distance instead of weight/reps.

## 1.1.0

- Fixed the "reps" label wrapping awkwardly between the +/- buttons on the active workout screen.
- Fixed new sets defaulting to an odd ~44.1 lbs — they now start at 0 and increment cleanly.
- Tap the number in any weight/reps/duration stepper to type a value directly instead of tapping +/- repeatedly.
- Added a delete button to remove an exercise from an in-progress workout.
- Saving a new workout template no longer immediately starts logging a session — it just saves. Start a saved workout from its new play button on the workout card.
