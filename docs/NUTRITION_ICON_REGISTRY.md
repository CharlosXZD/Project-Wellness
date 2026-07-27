# Nutrition Icon Registry — Project Wellness

Companion to [`docs/ICON_REGISTRY.md`](ICON_REGISTRY.md) (the workout/exercise icon bible), covering food, macros, supplements, and everything nutrition-related.

**Hard rule: no emojis. Ever.** See `feedback_no_emojis` in project memory. Every food marker in this app is a vector icon glyph, never a 🍎/🥑/🍕 character.

**Implementation status: live in code.** `lib/models/food_def.dart` has an optional `icon` override field; `lib/data/food_library.dart`'s `iconForFood()` resolves it, falling back to the category icon. `lib/features/nutrition/food_picker_screen.dart` renders it per-food. Package: `lucide_icons_flutter: ^3.1.15` — see the package-history note in `docs/ICON_REGISTRY.md` for why this is the only icon package here (both `material_design_icons_flutter` and `phosphor_flutter` fail to compile against this Flutter SDK; this doc's §2 originally recommended MDI, based on claimed icon names that were never build-verified — that recommendation was wrong).

---

## 1. Where we start from

`lib/data/food_library.dart` has `iconForFoodCategory()` mapping the app's 9 food categories to Material Icons, `iconForFood()` layering per-food overrides on top, and 228 individual foods across those categories, plus user-created entries in `lib/models/personal_food.dart` (same per-100g shape, category-icon only, no per-food override — see `lib/features/nutrition/personal_food_editor_screen.dart`). `lib/models/supplement.dart` tracks name/dosage/notes with no icon field yet. The nutrition screens (`nutrition_screen.dart`, `supplements_screen.dart`, `snacks_screen.dart`) currently reuse a handful of Material Icons: `restaurant`, `fastfood`, `medication_outlined`, `calculate_outlined`, `camera_alt_outlined` (label scan), `search`, `add_circle_outline`, `delete_outline`.

---

## 2. Correction: food icon coverage is real but narrower than originally claimed

The original version of this section claimed MDI and game-icons.net had broad literal food coverage (`fruit-grapes`, `chicken-leg`, etc.). That was never build-verified, and MDI is now confirmed entirely unusable in this project (see the package-history note near the top of `docs/ICON_REGISTRY.md`). The actually-verified library, `lucide_icons_flutter`, has real but modest food coverage — about 30 literal glyphs, confirmed by grepping its 1,991 base icon names directly:

**Confirmed present:** apple, banana, carrot, cherry, citrus (generic — used for orange, lemon, grapefruit), grape, broccoli, leaf / leafyGreen / sprout (generic greens), bean (generic legume), egg, fish (generic — used for salmon/tuna/cod/tilapia), shrimp, drumstick (generic poultry — used for chicken/turkey), beef, ham, nut (generic — used for peanuts/walnuts/cashews), milk, wheat, coffee, cupSoda, beer, wine, glassWater, popcorn, iceCream, donut, cake, croissant, hamburger, sandwich, salad, soup, pizza, candy, vegan.

**Confirmed absent (checked directly, not assumed):** mango, pomegranate, grapefruit (as distinct from citrus), blueberry, strawberry, watermelon, pineapple, peach, pear, avocado, kiwi, raspberry, plum, fig, spinach (has a leafy-green stand-in, not literal), onion, garlic, zucchini, cauliflower, lettuce, tomato, potato, mushroom, asparagus, cabbage, corn, beet, eggplant, celery, peas, rice, bread, pasta, bagel, tortilla, barley, oats, quinoa, couscous, cornmeal, chicken/turkey/pork as a specific cut, salmon/tuna/cod/tilapia as distinct species, tofu, tempeh, bacon, **cheese** (any variety), yogurt, butter, sour cream, almonds (specifically), walnuts/cashews (specifically — generic "nut" only), oil (any kind), mayonnaise, honey, sugar, pretzel, chips, granola bar, chocolate, "juice" (Material's `local_drink` glass icon is the fallback), "calorie"/"vitamin"/"hydration"/"recipe"/"fiber" as words.

For all of these, the pragmatic fallback is the **food-category icon** (already built). This is the same honest-limit pattern as the workout registry — Dairy in particular is a rough category (only Milk gets a literal icon; every cheese, yogurt, and butter falls back to the category default).

---

## 3. Library-by-library reference (nutrition-relevant names only — see the workout registry for full license/package details per library)

### Material Icons (built-in, `Icons.*`)
Already used: `local_florist`, `eco`, `rice_bowl`, `set_meal`, `icecream`, `grass`, `opacity`, `local_cafe`, `cookie`, `restaurant`, `fastfood`, `medication_outlined`.
Other real, stable names worth knowing: `local_grocery_store`, `shopping_cart`, `kitchen`, `qr_code_scanner`, `qr_code`, `water_drop`, `local_fire_department`, `egg`, `egg_alt`, `cake`, `local_pizza`, `local_bar`, `wine_bar`, `liquor`, `coffee`, `bakery_dining`, `breakfast_dining`, `lunch_dining`, `dinner_dining`, `ramen_dining`, `soup_kitchen`, `tapas`, `brunch_dining`, `grain`, `science` (flask/lab), `biotech`, `local_pharmacy`, `restaurant_menu`, `dining`.
Note: Material's `emoji_food_beverage` (a coffee-cup glyph) is a real vector icon, not an emoji character — but given the no-emoji rule, prefer `local_cafe` or `coffee` instead to sidestep the naming confusion entirely (same reasoning as `emoji_events` in the workout registry).

### Material Design Icons — MDI (`material_design_icons_flutter`)
The richest single set for literal food glyphs. Confirmed: `apple`, `fruit-grapes`, `fruit-grapes-outline`, `fruit-watermelon`, `fruit-pineapple`, `fruit-pear`, `fruit-citrus`, `carrot`, `mushroom`, `mushroom-outline`, `corn`, `pepper`, `pepper-off`, `rice`, `bread`, `wheat`, `wheat-off`, `pasta`, `barley`, `chicken-leg`, `chicken-leg-outline`, `beef`, `beef-off`, `fish`, `egg`, `egg-outline`, `turkey`, `turkey-leg`, `food-turkey`, `cheese`, `peanut`, `peanut-outline`, `oil`, `oil-can`, `coffee`, `bottle-soda`, `bottle-soda-classic`, `beer`, `wine`, `chocolate`, `chocolate-outline`, `chips`, `popcorn`, `honey-outline`, `sugar`, `pretzel`, `cupcake`, `candy`, `pizza`, `burger`, `mortar-pestle`, `pill`, `capsule`, `medicine-bottle`, `medicine-bottle-outline`, `barcode`, `local-grocery-store` *(same as Material's built-in name)*, `chef-hat`, `kitchen`, `kitchen-tap`, `flask`, `leaf`, `drop`, `drop-outline`, `water-drop`, `free-breakfast`, `free-breakfast-outline`, `dinner`, `dinner-bell`.

### game-icons.net
CC BY 3.0, attribution required, no Flutter package (SVG via `flutter_svg`). Surprisingly the deepest set for raw/whole-food glyphs: `banana`, `banana-bunch`, `banana-peel`, `strawberry`, `grapes`, `watermelon`, `pineapple`, `peach`, `pear`, `avocado`, `kiwi-fruit`, `cherry`, `raspberry`, `lemon`, `plum`, `orange`, `broccoli`, `carrot`, `potato`, `tomato`, `bell-pepper`, `chili-pepper`, `garlic`, `mushroom`, `corn`, `beet`, `asparagus`, `bread`, `wheat`, `chicken`, `chicken-leg`, `roast-chicken`, `salmon`, `shrimp`, `bacon`, `ham-shank`, `meat`, `meat-hook`, `milk-carton`, `butter`, `butter-toast`, `almond`, `peanut`, `coffee-beans`, `oil-can`, `oil-drum`, `soda-can`, `soda-bottle`, `chocolate-bar`, `chips-bag`, `popcorn`, `honey-jar`, `dripping-honey`, `sugar-cane`, `pretzel`, `donut`, `cupcake`, `sandwich`, `water-drop`, `weight-scale`, `medicine-pills`, `health-capsule`.

### Tabler Icons (`flutter_tabler_icons` / `tabler_icons_flutter`)
Confirmed: `apple`, `banana`, `avocado`, `cherry`, `cherry-filled`, `lemon`, `lemon-2`, `carrot`, `pepper`, `pepper-off`, `mushroom`, `bread`, `wheat`, `fish`, `egg`, `egg-filled`, `milk`, `milk-off`, `cheese`, `ice-cream`, `chocolate`, `popcorn`, `pretzel` *(verify — not directly confirmed for Tabler, MDI/game-icons confirmed instead)*, `candy`, `candy-cane`, `pizza`, `burger`, `sandwich` *(verify — Lucide/game-icons confirmed, not directly Tabler)*, `salad`, `salad-filled`, `soup`, `soup-filled`, `soup-off`, `cookie`, `pill`, `capsule`, `flask`, `flask-filled`, `leaf`, `droplet`, `droplet-filled`, `barcode`, `shopping-cart`, `chef-hat`, `macro`, `macro-filled`.

### Phosphor Icons (`phosphor_flutter`)
Confirmed: `Orange` (6 weights), `Avocado`, `Carrot`, `Pepper`, `Cheese`, `Bread`, `Fish`, `Shrimp`, `IceCream`, `Popcorn`, `Pizza`, `Wine`, `Cookie`, `Pill`, `Barcode`, `ChefHat`, `Tray`, `Flask`, `Drop`.

### Lucide (`lucide_icons` / `lucide_icons_flutter`)
Confirmed: `apple`, `banana`, `cherry`, `carrot`, `broccoli`, `wheat`, `wheat-off`, `beef`, `beef-off`, `fish`, `shrimp`, `egg`, `milk`, `milk-off`, `ham`, `coffee`, `wine`, `beer`, `cup-soda`, `donut`, `candy`, `candy-off`, `candy-cane`, `cookie`, `pizza`, `sandwich`, `salad`, `soup`, `popcorn`, `nut`, `nut-off`, `pill`, `flask-round`, `leaf`, `droplet`, `barcode`, `shopping-cart`, `chef-hat`.

### Font Awesome (Free), Remix, Iconoir, Ionicons, Boxicons, Health Icons
Scattered but useful confirmed hits: FA6 `kiwi-bird`, `lemon`, `carrot`, `pepper-hot`, `shrimp`, `bacon`, `ice-cream`, `burger`, `mortar-pestle`, `weight-scale`; Iconoir `apple`, `fish`, `chocolate`, `cookie`, `flask`, `flask-solid`, `leaf`, `droplet`, `barcode`; Ionicons `fish`, `egg`, `pizza`, `beer`, `wine`, `ice-cream`, `nutrition`/`nutrition-outline` *(Ionicons is the only set with a literal "nutrition" glyph)*, `leaf`; Health Icons (public domain, SVG-only) `carbohydrates`/`carbohydrates-outline` *(the only set with a literal macro glyph)*, `sugar`/`sugar-outline`/`sugar-free`, `hot-meal`/`hot-meal-outline`, `medicine-bottle`, `medicine-mortar`, `animal-chicken`.

---

## 4. Recommendation

Superseded — see the correction in §2 and the package-history note in `docs/ICON_REGISTRY.md`. `material_design_icons_flutter` cannot be used (fails to compile against this Flutter SDK). `lucide_icons_flutter` is what's actually installed and used; its real coverage is documented in §2 and applied per-food in §6 below. If you want to expand coverage further (mango, kale, spinach-specific, cheese, etc.), the honest options are: bundle SVGs via `flutter_svg` from a CC0/CC-BY source like Health Icons or game-icons.net (crediting artists for the latter), or accept the category-icon fallback — don't add another icon-font package without running `flutter test` against it first (two out of three tried this session failed to compile).

---

## 5. Concept → icon map

### 5a. Food categories (current — already implemented in `food_library.dart`)

| Category | Material Icons (current) |
|---|---|
| Fruits | `Icons.local_florist` |
| Vegetables | `Icons.eco` |
| Grains | `Icons.rice_bowl` |
| Protein | `Icons.set_meal` |
| Dairy | `Icons.icecream` |
| Legumes & Nuts | `Icons.grass` |
| Fats & Oils | `Icons.opacity` |
| Beverages | `Icons.local_cafe` |
| Snacks & Sweets | `Icons.cookie` |

### 5b. Macros & metrics (no exact-word glyphs exist anywhere for most of these — these are the universal fitness-app conventions instead)

| Concept | Icon | Note |
|---|---|---|
| Protein | `set_meal` (Material, already used) | reuse Protein category icon |
| Carbs | `healthicons:carbohydrates` if using SVGs, else `rice_bowl` | Health Icons is the only set with a literal glyph |
| Fat | `Icons.opacity` (already used for Fats & Oils) | droplet is the universal nutrition-label convention |
| Fiber | `Icons.eco` or `mdi:leaf` | no dedicated glyph anywhere; reuse the leafy/plant convention |
| Calories / kcal | `Icons.local_fire_department` | no dedicated glyph anywhere; flame is universal (same as "streak" in the workout registry) |
| Water / hydration | `Icons.water_drop` | `mdi:water-drop`, `tabler:droplet`, `lucide:droplet` all equivalent |
| Body weight | `Icons.monitor_weight` / `Icons.scale` | `mdi:scale`, `game-icons:weight-scale` |

### 5c. Supplements & vitamins

| Concept | Icon |
|---|---|
| Generic supplement/vitamin (default) | `Icons.medication_outlined` (already used) / `mdi:pill` |
| Capsule form | `mdi:capsule`, `tabler:capsule`, `ri:capsule-fill` |
| Medicine bottle | `mdi:medicine-bottle`, `healthicons:medicine-bottle` |
| Natural/herbal remedy | `mdi:mortar-pestle`, `fa6-solid:mortar-pestle` |
| Lab-tested / science-branded supplement | `mdi:flask`, `tabler:flask`, `lucide:flask-round` |

No library anywhere has a dedicated "vitamin" glyph distinct from a generic pill/capsule — that's the universal convention, not a gap to keep searching for.

### 5d. Meal types

| Meal | Icon |
|---|---|
| Breakfast | `mdi:free-breakfast` (exact — Google/MDI both use a coffee-cup glyph for this) |
| Lunch | No dedicated glyph anywhere; fall back to `Icons.restaurant` or `Icons.lunch_dining` (Material has this built-in even though MDI/others don't) |
| Dinner | `mdi:dinner`, `mdi:dinner-bell`, or Material's built-in `Icons.dinner_dining` |
| Snack | `Icons.fastfood` (already used in `snacks_screen.dart`) |

### 5e. App UI

| Concept | Icon |
|---|---|
| Scan barcode/label | `mdi:barcode`, `tabler:barcode`, `lucide:barcode`, or Material's built-in `Icons.qr_code_scanner` — consider swapping the current `camera_alt_outlined` in `nutrition_screen.dart` for `qr_code_scanner` since it reads more literally as "scan this" |
| Grocery / shopping list | `Icons.local_grocery_store` (built-in), `mdi:shopping-cart` |
| Recipe | No literal glyph anywhere; use `chef_hat` equivalent — Material has no built-in chef hat, so this is a case for pulling in `mdi:chef-hat` / `tabler:chef-hat` / `lucide:chef-hat` |
| Kitchen | `Icons.kitchen` (built-in) |

---

## 6. Food-by-food recommendation

Generated from `lib/data/food_library.dart` — a direct reflection of the `icon` tag on every `FoodDef`, not a hand-maintained plan. Regenerate this section from the code if it ever looks out of sync.

**228 foods total, 97 with a distinct per-food icon** (97/228); the rest fall back to the category icon because no honest glyph exists for them in Lucide or Material (see §2). Every food also optionally carries `fiberPer100g`/`sugarPer100g`/`sodiumMgPer100g` on `FoodDef` — filled in where reasonably known, null where not; this is separate from icon coverage and not tracked in this table.

### Fruits (category icon: `local_florist`)
| Food | Icon |
|---|---|
| Apple | LucideIcons.apple |
| Banana | LucideIcons.banana |
| Orange | LucideIcons.citrus |
| Strawberries | *category default* |
| Blueberries | *category default* |
| Grapes | LucideIcons.grape |
| Watermelon | *category default* |
| Pineapple | *category default* |
| Mango | *category default* |
| Peach | *category default* |
| Pear | *category default* |
| Avocado | *category default* |
| Kiwi | *category default* |
| Cherries | LucideIcons.cherry |
| Raspberries | *category default* |
| Pomegranate | *category default* |
| Lemon | LucideIcons.citrus |
| Grapefruit | LucideIcons.citrus |
| Plum | *category default* |
| Fig | *category default* |
| Cantaloupe | *category default* |
| Honeydew Melon | *category default* |
| Papaya | *category default* |
| Dragonfruit | *category default* |
| Apricot | *category default* |
| Nectarine | *category default* |
| Guava | *category default* |
| Passion Fruit | *category default* |
| Persimmon | *category default* |
| Star Fruit | *category default* |
| Cranberries | *category default* |
| Blackberries | *category default* |
| Dates | *category default* |
| Coconut Meat | *category default* |
| Tangerine | LucideIcons.citrus |

### Vegetables (category icon: `eco`)
| Food | Icon |
|---|---|
| Broccoli | LucideIcons.broccoli |
| Spinach | LucideIcons.leafyGreen |
| Carrot | LucideIcons.carrot |
| Kale | LucideIcons.leaf |
| Potato | *category default* |
| Sweet Potato | *category default* |
| Tomato | *category default* |
| Cucumber | *category default* |
| Bell Pepper | *category default* |
| Onion | *category default* |
| Garlic | *category default* |
| Zucchini | *category default* |
| Cauliflower | *category default* |
| Lettuce | *category default* |
| Mushroom | *category default* |
| Asparagus | *category default* |
| Green Beans | LucideIcons.bean |
| Cabbage | *category default* |
| Corn | *category default* |
| Beet | *category default* |
| Eggplant | *category default* |
| Celery | *category default* |
| Brussels Sprouts | LucideIcons.sprout |
| Peas | *category default* |
| Radish | *category default* |
| Turnip | *category default* |
| Parsnip | *category default* |
| Leek | *category default* |
| Fennel | *category default* |
| Artichoke | *category default* |
| Okra | *category default* |
| Bok Choy | LucideIcons.leafyGreen |
| Collard Greens | LucideIcons.leaf |
| Swiss Chard | LucideIcons.leafyGreen |
| Arugula | LucideIcons.leaf |
| Watercress | LucideIcons.leaf |
| Snap Peas | LucideIcons.bean |
| Butternut Squash | *category default* |
| Pumpkin | *category default* |
| Jicama | *category default* |
| Rutabaga | *category default* |
| Kohlrabi | *category default* |

### Grains (category icon: `rice_bowl`)
| Food | Icon |
|---|---|
| White Rice (cooked) | *category default* |
| Brown Rice (cooked) | *category default* |
| Oats (dry) | *category default* |
| Quinoa (cooked) | *category default* |
| White Bread | Icons.bakery_dining |
| Whole Wheat Bread | LucideIcons.wheat |
| Pasta (cooked) | Icons.ramen_dining |
| Couscous (cooked) | *category default* |
| Bagel | Icons.bakery_dining |
| Tortilla (flour) | *category default* |
| Cornmeal | *category default* |
| Barley (cooked) | *category default* |
| Farro (cooked) | *category default* |
| Bulgur (cooked) | *category default* |
| Millet (cooked) | *category default* |
| Rye Bread | Icons.bakery_dining |
| Sourdough Bread | Icons.bakery_dining |
| Pita Bread | Icons.bakery_dining |
| Naan | *category default* |
| Corn Flakes | *category default* |
| Cream of Wheat (cooked) | *category default* |
| Wild Rice (cooked) | *category default* |

### Protein (category icon: `set_meal`)
| Food | Icon |
|---|---|
| Chicken Breast | LucideIcons.drumstick |
| Chicken Thigh | LucideIcons.drumstick |
| Beef (85% lean) | LucideIcons.beef |
| Beef Sirloin Steak | LucideIcons.beef |
| Pork Chop | *category default* |
| Salmon | LucideIcons.fish |
| Tuna (canned, water) | LucideIcons.fish |
| Shrimp | LucideIcons.shrimp |
| Cod | LucideIcons.fish |
| Tilapia | LucideIcons.fish |
| Egg (whole) | LucideIcons.egg |
| Egg Whites | LucideIcons.egg |
| Turkey Breast | LucideIcons.drumstick |
| Tofu | *category default* |
| Tempeh | *category default* |
| Bacon | *category default* |
| Ham | LucideIcons.ham |
| Lamb | *category default* |
| Duck | LucideIcons.drumstick |
| Venison | *category default* |
| Bison | LucideIcons.beef |
| Veal | *category default* |
| Chicken Wing | LucideIcons.drumstick |
| Chicken Drumstick | LucideIcons.drumstick |
| Ground Turkey (93% lean) | LucideIcons.drumstick |
| Ground Beef (90% lean) | LucideIcons.beef |
| Ground Beef (80% lean) | LucideIcons.beef |
| Pork Sausage | *category default* |
| Chorizo | *category default* |
| Salami | *category default* |
| Pepperoni | *category default* |
| Halibut | LucideIcons.fish |
| Mahi Mahi | LucideIcons.fish |
| Sardines (canned) | LucideIcons.fish |
| Anchovies | LucideIcons.fish |
| Crab | *category default* |
| Lobster | *category default* |
| Scallops | *category default* |
| Mussels | *category default* |
| Clams | *category default* |
| Octopus | *category default* |

### Dairy (category icon: `icecream`)
| Food | Icon |
|---|---|
| Milk (whole) | LucideIcons.milk |
| Milk (skim) | LucideIcons.milk |
| Greek Yogurt (plain) | *category default* |
| Yogurt (plain, whole) | *category default* |
| Cheddar Cheese | *category default* |
| Mozzarella | *category default* |
| Cottage Cheese | *category default* |
| Parmesan | *category default* |
| Butter | *category default* |
| Cream Cheese | *category default* |
| Sour Cream | *category default* |
| Swiss Cheese | *category default* |
| Feta Cheese | *category default* |
| Goat Cheese | *category default* |
| Ricotta | *category default* |
| Provolone | *category default* |
| Blue Cheese | *category default* |
| Half and Half | *category default* |
| Whipped Cream | *category default* |
| Kefir | LucideIcons.milk |
| Buttermilk | LucideIcons.milk |

### Legumes & Nuts (category icon: `grass`)
| Food | Icon |
|---|---|
| Almonds | *category default* |
| Peanuts | LucideIcons.nut |
| Walnuts | LucideIcons.nut |
| Cashews | LucideIcons.nut |
| Peanut Butter | LucideIcons.nut |
| Black Beans (cooked) | LucideIcons.bean |
| Chickpeas (cooked) | LucideIcons.bean |
| Lentils (cooked) | LucideIcons.bean |
| Kidney Beans (cooked) | LucideIcons.bean |
| Edamame | LucideIcons.bean |
| Chia Seeds | LucideIcons.sprout |
| Flaxseeds | LucideIcons.sprout |
| Pistachios | LucideIcons.nut |
| Macadamia Nuts | LucideIcons.nut |
| Brazil Nuts | LucideIcons.nut |
| Hazelnuts | LucideIcons.nut |
| Pine Nuts | LucideIcons.nut |
| Pecans | LucideIcons.nut |
| Soybeans (cooked) | LucideIcons.bean |
| Almond Butter | LucideIcons.nut |
| Sunflower Seeds | LucideIcons.nut |
| Pumpkin Seeds | LucideIcons.nut |

### Fats & Oils (category icon: `opacity`)
| Food | Icon |
|---|---|
| Olive Oil | *category default* |
| Coconut Oil | *category default* |
| Vegetable Oil | *category default* |
| Mayonnaise | *category default* |
| Avocado Oil | *category default* |
| Sesame Oil | *category default* |
| Ghee | *category default* |
| Lard | *category default* |

### Beverages (category icon: `local_cafe`)
| Food | Icon |
|---|---|
| Orange Juice | Icons.local_drink |
| Apple Juice | Icons.local_drink |
| Coffee (black) | LucideIcons.coffee |
| Soda (cola) | LucideIcons.cupSoda |
| Beer | LucideIcons.beer |
| Wine (red) | LucideIcons.wine |
| Whey Protein Shake (water) | LucideIcons.glassWater |
| Almond Milk (unsweetened) | LucideIcons.milk |
| Soy Milk | LucideIcons.milk |
| Oat Milk | LucideIcons.milk |
| Coconut Water | LucideIcons.glassWater |
| Sports Drink | LucideIcons.cupSoda |
| Energy Drink | LucideIcons.cupSoda |
| Tea (unsweetened) | *category default* |
| Diet Soda | LucideIcons.cupSoda |

### Snacks & Sweets (category icon: `cookie`)
| Food | Icon |
|---|---|
| Dark Chocolate | *category default* |
| Milk Chocolate | *category default* |
| Potato Chips | *category default* |
| Popcorn (air-popped) | LucideIcons.popcorn |
| Granola Bar | *category default* |
| Honey | *category default* |
| White Sugar | *category default* |
| Ice Cream | LucideIcons.iceCream |
| Pretzels | *category default* |
| Donut | LucideIcons.donut |
| Protein Bar | *category default* |
| Trail Mix | LucideIcons.nut |
| Rice Cakes | *category default* |
| Crackers (saltine) | *category default* |
| Waffle | *category default* |
| Pancake | *category default* |
| Muffin (blueberry) | *category default* |
| Croissant | LucideIcons.croissant |
| Cake (frosted, chocolate) | LucideIcons.cake |
| Chocolate Chip Cookie | LucideIcons.cookie |
| Jam / Jelly | *category default* |
| Maple Syrup | *category default* |


## 7. Adding a new icon package — checklist

Same as the workout registry (§7 there): confirm the exact glyph name on the library's live browser before writing code, never use an emoji as a placeholder, credit CC-BY sources (game-icons.net) in a credits screen, and keep this file in sync with `food_library.dart` as foods are added.
