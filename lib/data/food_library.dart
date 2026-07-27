import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/food_def.dart';

const List<String> foodCategories = [
  'Fruits',
  'Vegetables',
  'Grains',
  'Protein',
  'Dairy',
  'Legumes & Nuts',
  'Fats & Oils',
  'Beverages',
  'Snacks & Sweets',
];

IconData iconForFoodCategory(String category) {
  switch (category) {
    case 'Fruits':
      return Icons.local_florist;
    case 'Vegetables':
      return Icons.eco;
    case 'Grains':
      return Icons.rice_bowl;
    case 'Protein':
      return Icons.set_meal;
    case 'Dairy':
      return Icons.icecream;
    case 'Legumes & Nuts':
      return Icons.grass;
    case 'Fats & Oils':
      return Icons.opacity;
    case 'Beverages':
      return Icons.local_cafe;
    case 'Snacks & Sweets':
      return Icons.cookie;
    default:
      return Icons.restaurant;
  }
}

/// Resolves the icon for a single food: explicit per-food override (a literal
/// glyph via `lucide_icons_flutter` or Material), else the category default.
/// `lucide_icons_flutter` was verified to actually compile against this
/// Flutter SDK (unlike `material_design_icons_flutter`, see
/// docs/ICON_REGISTRY.md §2) but its real food coverage is much narrower
/// than hoped — about 30 literal glyphs, mostly whole fruit/veg/protein
/// terms, no cheese/bread/oil/sugar/most vegetables. See
/// docs/NUTRITION_ICON_REGISTRY.md for the honest per-food breakdown.
IconData iconForFood(FoodDef food) {
  return food.icon ?? iconForFoodCategory(food.category);
}

/// Per-100g nutrition values, approximate USDA-style figures. Fiber/sugar/
/// sodium are filled in where reasonably known; null where they aren't —
/// see docs/NUTRITION_ICON_REGISTRY.md for the icon side of this data.
const List<FoodDef> foodLibrary = [
  // Fruits
  FoodDef(name: 'Apple', category: 'Fruits', caloriesPer100g: 52, proteinPer100g: 0.3, carbsPer100g: 14, fatPer100g: 0.2, fiberPer100g: 2.4, sugarPer100g: 10.4, sodiumMgPer100g: 1, icon: LucideIcons.apple),
  FoodDef(name: 'Banana', category: 'Fruits', caloriesPer100g: 89, proteinPer100g: 1.1, carbsPer100g: 23, fatPer100g: 0.3, fiberPer100g: 2.6, sugarPer100g: 12, sodiumMgPer100g: 1, icon: LucideIcons.banana),
  FoodDef(name: 'Orange', category: 'Fruits', caloriesPer100g: 47, proteinPer100g: 0.9, carbsPer100g: 12, fatPer100g: 0.1, fiberPer100g: 2.4, sugarPer100g: 9.4, sodiumMgPer100g: 0, icon: LucideIcons.citrus),
  FoodDef(name: 'Strawberries', category: 'Fruits', caloriesPer100g: 32, proteinPer100g: 0.7, carbsPer100g: 8, fatPer100g: 0.3, fiberPer100g: 2, sugarPer100g: 4.9, sodiumMgPer100g: 1),
  FoodDef(name: 'Blueberries', category: 'Fruits', caloriesPer100g: 57, proteinPer100g: 0.7, carbsPer100g: 14, fatPer100g: 0.3, fiberPer100g: 2.4, sugarPer100g: 10, sodiumMgPer100g: 1),
  FoodDef(name: 'Grapes', category: 'Fruits', caloriesPer100g: 69, proteinPer100g: 0.7, carbsPer100g: 18, fatPer100g: 0.2, icon: LucideIcons.grape),
  FoodDef(name: 'Watermelon', category: 'Fruits', caloriesPer100g: 30, proteinPer100g: 0.6, carbsPer100g: 8, fatPer100g: 0.2),
  FoodDef(name: 'Pineapple', category: 'Fruits', caloriesPer100g: 50, proteinPer100g: 0.5, carbsPer100g: 13, fatPer100g: 0.1),
  FoodDef(name: 'Mango', category: 'Fruits', caloriesPer100g: 60, proteinPer100g: 0.8, carbsPer100g: 15, fatPer100g: 0.4),
  FoodDef(name: 'Peach', category: 'Fruits', caloriesPer100g: 39, proteinPer100g: 0.9, carbsPer100g: 10, fatPer100g: 0.3),
  FoodDef(name: 'Pear', category: 'Fruits', caloriesPer100g: 57, proteinPer100g: 0.4, carbsPer100g: 15, fatPer100g: 0.1),
  FoodDef(name: 'Avocado', category: 'Fruits', caloriesPer100g: 160, proteinPer100g: 2, carbsPer100g: 9, fatPer100g: 15, fiberPer100g: 6.7, sugarPer100g: 0.7, sodiumMgPer100g: 7),
  FoodDef(name: 'Kiwi', category: 'Fruits', caloriesPer100g: 61, proteinPer100g: 1.1, carbsPer100g: 15, fatPer100g: 0.5),
  FoodDef(name: 'Cherries', category: 'Fruits', caloriesPer100g: 63, proteinPer100g: 1.1, carbsPer100g: 16, fatPer100g: 0.2, icon: LucideIcons.cherry),
  FoodDef(name: 'Raspberries', category: 'Fruits', caloriesPer100g: 52, proteinPer100g: 1.2, carbsPer100g: 12, fatPer100g: 0.7),
  FoodDef(name: 'Pomegranate', category: 'Fruits', caloriesPer100g: 83, proteinPer100g: 1.7, carbsPer100g: 19, fatPer100g: 1.2),
  FoodDef(name: 'Lemon', category: 'Fruits', caloriesPer100g: 29, proteinPer100g: 1.1, carbsPer100g: 9, fatPer100g: 0.3, icon: LucideIcons.citrus),
  FoodDef(name: 'Grapefruit', category: 'Fruits', caloriesPer100g: 42, proteinPer100g: 0.8, carbsPer100g: 11, fatPer100g: 0.1, icon: LucideIcons.citrus),
  FoodDef(name: 'Plum', category: 'Fruits', caloriesPer100g: 46, proteinPer100g: 0.7, carbsPer100g: 11, fatPer100g: 0.3),
  FoodDef(name: 'Fig', category: 'Fruits', caloriesPer100g: 74, proteinPer100g: 0.8, carbsPer100g: 19, fatPer100g: 0.3),
  FoodDef(name: 'Cantaloupe', category: 'Fruits', caloriesPer100g: 34, proteinPer100g: 0.8, carbsPer100g: 8, fatPer100g: 0.2, fiberPer100g: 0.9, sugarPer100g: 8, sodiumMgPer100g: 16),
  FoodDef(name: 'Honeydew Melon', category: 'Fruits', caloriesPer100g: 36, proteinPer100g: 0.5, carbsPer100g: 9, fatPer100g: 0.1, fiberPer100g: 0.8, sugarPer100g: 8, sodiumMgPer100g: 18),
  FoodDef(name: 'Papaya', category: 'Fruits', caloriesPer100g: 43, proteinPer100g: 0.5, carbsPer100g: 11, fatPer100g: 0.3, fiberPer100g: 1.7, sugarPer100g: 8, sodiumMgPer100g: 8),
  FoodDef(name: 'Dragonfruit', category: 'Fruits', caloriesPer100g: 60, proteinPer100g: 1.2, carbsPer100g: 13, fatPer100g: 0.4, fiberPer100g: 3, sugarPer100g: 8, sodiumMgPer100g: 0),
  FoodDef(name: 'Apricot', category: 'Fruits', caloriesPer100g: 48, proteinPer100g: 1.4, carbsPer100g: 11, fatPer100g: 0.4, fiberPer100g: 2, sugarPer100g: 9, sodiumMgPer100g: 1),
  FoodDef(name: 'Nectarine', category: 'Fruits', caloriesPer100g: 44, proteinPer100g: 1.1, carbsPer100g: 11, fatPer100g: 0.3, fiberPer100g: 1.7, sugarPer100g: 8, sodiumMgPer100g: 0),
  FoodDef(name: 'Guava', category: 'Fruits', caloriesPer100g: 68, proteinPer100g: 2.6, carbsPer100g: 14, fatPer100g: 1, fiberPer100g: 5.4, sugarPer100g: 9, sodiumMgPer100g: 2),
  FoodDef(name: 'Passion Fruit', category: 'Fruits', caloriesPer100g: 97, proteinPer100g: 2.2, carbsPer100g: 23, fatPer100g: 0.7, fiberPer100g: 10.4, sugarPer100g: 11, sodiumMgPer100g: 28),
  FoodDef(name: 'Persimmon', category: 'Fruits', caloriesPer100g: 70, proteinPer100g: 0.6, carbsPer100g: 19, fatPer100g: 0.2, fiberPer100g: 3.6, sugarPer100g: 13, sodiumMgPer100g: 1),
  FoodDef(name: 'Star Fruit', category: 'Fruits', caloriesPer100g: 31, proteinPer100g: 1, carbsPer100g: 7, fatPer100g: 0.3, fiberPer100g: 2.8, sugarPer100g: 4, sodiumMgPer100g: 2),
  FoodDef(name: 'Cranberries', category: 'Fruits', caloriesPer100g: 46, proteinPer100g: 0.4, carbsPer100g: 12, fatPer100g: 0.1, fiberPer100g: 4.6, sugarPer100g: 4, sodiumMgPer100g: 2),
  FoodDef(name: 'Blackberries', category: 'Fruits', caloriesPer100g: 43, proteinPer100g: 1.4, carbsPer100g: 10, fatPer100g: 0.5, fiberPer100g: 5.3, sugarPer100g: 4.9, sodiumMgPer100g: 1),
  FoodDef(name: 'Dates', category: 'Fruits', caloriesPer100g: 282, proteinPer100g: 2.5, carbsPer100g: 75, fatPer100g: 0.4, fiberPer100g: 8, sugarPer100g: 63, sodiumMgPer100g: 1),
  FoodDef(name: 'Coconut Meat', category: 'Fruits', caloriesPer100g: 354, proteinPer100g: 3.3, carbsPer100g: 15, fatPer100g: 33, fiberPer100g: 9, sugarPer100g: 6, sodiumMgPer100g: 20),
  FoodDef(name: 'Tangerine', category: 'Fruits', caloriesPer100g: 53, proteinPer100g: 0.8, carbsPer100g: 13, fatPer100g: 0.3, fiberPer100g: 1.8, sugarPer100g: 11, sodiumMgPer100g: 2, icon: LucideIcons.citrus),

  // Vegetables
  FoodDef(name: 'Broccoli', category: 'Vegetables', caloriesPer100g: 34, proteinPer100g: 2.8, carbsPer100g: 7, fatPer100g: 0.4, fiberPer100g: 2.6, sugarPer100g: 1.7, sodiumMgPer100g: 33, icon: LucideIcons.broccoli),
  FoodDef(name: 'Spinach', category: 'Vegetables', caloriesPer100g: 23, proteinPer100g: 2.9, carbsPer100g: 3.6, fatPer100g: 0.4, fiberPer100g: 2.2, sugarPer100g: 0.4, sodiumMgPer100g: 79, icon: LucideIcons.leafyGreen),
  FoodDef(name: 'Carrot', category: 'Vegetables', caloriesPer100g: 41, proteinPer100g: 0.9, carbsPer100g: 10, fatPer100g: 0.2, fiberPer100g: 2.8, sugarPer100g: 4.7, sodiumMgPer100g: 69, icon: LucideIcons.carrot),
  FoodDef(name: 'Kale', category: 'Vegetables', caloriesPer100g: 49, proteinPer100g: 4.3, carbsPer100g: 9, fatPer100g: 0.9, fiberPer100g: 3.6, sugarPer100g: 0.8, sodiumMgPer100g: 38, icon: LucideIcons.leaf),
  FoodDef(name: 'Potato', category: 'Vegetables', caloriesPer100g: 77, proteinPer100g: 2, carbsPer100g: 17, fatPer100g: 0.1, fiberPer100g: 2.2, sugarPer100g: 0.8, sodiumMgPer100g: 6),
  FoodDef(name: 'Sweet Potato', category: 'Vegetables', caloriesPer100g: 86, proteinPer100g: 1.6, carbsPer100g: 20, fatPer100g: 0.1, fiberPer100g: 3, sugarPer100g: 4.2, sodiumMgPer100g: 55),
  FoodDef(name: 'Tomato', category: 'Vegetables', caloriesPer100g: 18, proteinPer100g: 0.9, carbsPer100g: 3.9, fatPer100g: 0.2, fiberPer100g: 1.2, sugarPer100g: 2.6, sodiumMgPer100g: 5),
  FoodDef(name: 'Cucumber', category: 'Vegetables', caloriesPer100g: 15, proteinPer100g: 0.7, carbsPer100g: 3.6, fatPer100g: 0.1),
  FoodDef(name: 'Bell Pepper', category: 'Vegetables', caloriesPer100g: 31, proteinPer100g: 1, carbsPer100g: 6, fatPer100g: 0.3),
  FoodDef(name: 'Onion', category: 'Vegetables', caloriesPer100g: 40, proteinPer100g: 1.1, carbsPer100g: 9, fatPer100g: 0.1),
  FoodDef(name: 'Garlic', category: 'Vegetables', caloriesPer100g: 149, proteinPer100g: 6.4, carbsPer100g: 33, fatPer100g: 0.5),
  FoodDef(name: 'Zucchini', category: 'Vegetables', caloriesPer100g: 17, proteinPer100g: 1.2, carbsPer100g: 3.1, fatPer100g: 0.3),
  FoodDef(name: 'Cauliflower', category: 'Vegetables', caloriesPer100g: 25, proteinPer100g: 1.9, carbsPer100g: 5, fatPer100g: 0.3),
  FoodDef(name: 'Lettuce', category: 'Vegetables', caloriesPer100g: 15, proteinPer100g: 1.4, carbsPer100g: 2.9, fatPer100g: 0.2),
  FoodDef(name: 'Mushroom', category: 'Vegetables', caloriesPer100g: 22, proteinPer100g: 3.1, carbsPer100g: 3.3, fatPer100g: 0.3),
  FoodDef(name: 'Asparagus', category: 'Vegetables', caloriesPer100g: 20, proteinPer100g: 2.2, carbsPer100g: 3.9, fatPer100g: 0.1),
  FoodDef(name: 'Green Beans', category: 'Vegetables', caloriesPer100g: 31, proteinPer100g: 1.8, carbsPer100g: 7, fatPer100g: 0.2, icon: LucideIcons.bean),
  FoodDef(name: 'Cabbage', category: 'Vegetables', caloriesPer100g: 25, proteinPer100g: 1.3, carbsPer100g: 6, fatPer100g: 0.1),
  FoodDef(name: 'Corn', category: 'Vegetables', caloriesPer100g: 96, proteinPer100g: 3.4, carbsPer100g: 21, fatPer100g: 1.5),
  FoodDef(name: 'Beet', category: 'Vegetables', caloriesPer100g: 43, proteinPer100g: 1.6, carbsPer100g: 10, fatPer100g: 0.2),
  FoodDef(name: 'Eggplant', category: 'Vegetables', caloriesPer100g: 25, proteinPer100g: 1, carbsPer100g: 6, fatPer100g: 0.2),
  FoodDef(name: 'Celery', category: 'Vegetables', caloriesPer100g: 16, proteinPer100g: 0.7, carbsPer100g: 3, fatPer100g: 0.2),
  FoodDef(name: 'Brussels Sprouts', category: 'Vegetables', caloriesPer100g: 43, proteinPer100g: 3.4, carbsPer100g: 9, fatPer100g: 0.3, icon: LucideIcons.sprout),
  FoodDef(name: 'Peas', category: 'Vegetables', caloriesPer100g: 81, proteinPer100g: 5.4, carbsPer100g: 14, fatPer100g: 0.4),
  FoodDef(name: 'Radish', category: 'Vegetables', caloriesPer100g: 16, proteinPer100g: 0.7, carbsPer100g: 3.4, fatPer100g: 0.1, fiberPer100g: 1.6, sugarPer100g: 1.9, sodiumMgPer100g: 39),
  FoodDef(name: 'Turnip', category: 'Vegetables', caloriesPer100g: 28, proteinPer100g: 0.9, carbsPer100g: 6.4, fatPer100g: 0.1, fiberPer100g: 1.8, sugarPer100g: 3.8, sodiumMgPer100g: 67),
  FoodDef(name: 'Parsnip', category: 'Vegetables', caloriesPer100g: 75, proteinPer100g: 1.2, carbsPer100g: 18, fatPer100g: 0.3, fiberPer100g: 4.9, sugarPer100g: 4.8, sodiumMgPer100g: 10),
  FoodDef(name: 'Leek', category: 'Vegetables', caloriesPer100g: 61, proteinPer100g: 1.5, carbsPer100g: 14, fatPer100g: 0.3, fiberPer100g: 1.8, sugarPer100g: 3.9, sodiumMgPer100g: 20),
  FoodDef(name: 'Fennel', category: 'Vegetables', caloriesPer100g: 31, proteinPer100g: 1.2, carbsPer100g: 7.3, fatPer100g: 0.2, fiberPer100g: 3.1, sugarPer100g: 3.9, sodiumMgPer100g: 52),
  FoodDef(name: 'Artichoke', category: 'Vegetables', caloriesPer100g: 47, proteinPer100g: 3.3, carbsPer100g: 11, fatPer100g: 0.2, fiberPer100g: 5.4, sugarPer100g: 1, sodiumMgPer100g: 94),
  FoodDef(name: 'Okra', category: 'Vegetables', caloriesPer100g: 33, proteinPer100g: 1.9, carbsPer100g: 7.5, fatPer100g: 0.2, fiberPer100g: 3.2, sugarPer100g: 1.5, sodiumMgPer100g: 7),
  FoodDef(name: 'Bok Choy', category: 'Vegetables', caloriesPer100g: 13, proteinPer100g: 1.5, carbsPer100g: 2.2, fatPer100g: 0.2, fiberPer100g: 1, sugarPer100g: 1.2, sodiumMgPer100g: 65, icon: LucideIcons.leafyGreen),
  FoodDef(name: 'Collard Greens', category: 'Vegetables', caloriesPer100g: 32, proteinPer100g: 3, carbsPer100g: 5.4, fatPer100g: 0.6, fiberPer100g: 4, sugarPer100g: 0.5, sodiumMgPer100g: 20, icon: LucideIcons.leaf),
  FoodDef(name: 'Swiss Chard', category: 'Vegetables', caloriesPer100g: 19, proteinPer100g: 1.8, carbsPer100g: 3.7, fatPer100g: 0.2, fiberPer100g: 1.6, sugarPer100g: 1.1, sodiumMgPer100g: 213, icon: LucideIcons.leafyGreen),
  FoodDef(name: 'Arugula', category: 'Vegetables', caloriesPer100g: 25, proteinPer100g: 2.6, carbsPer100g: 3.7, fatPer100g: 0.7, fiberPer100g: 1.6, sugarPer100g: 2, sodiumMgPer100g: 27, icon: LucideIcons.leaf),
  FoodDef(name: 'Watercress', category: 'Vegetables', caloriesPer100g: 11, proteinPer100g: 2.3, carbsPer100g: 1.3, fatPer100g: 0.1, fiberPer100g: 0.5, sugarPer100g: 0.2, sodiumMgPer100g: 41, icon: LucideIcons.leaf),
  FoodDef(name: 'Snap Peas', category: 'Vegetables', caloriesPer100g: 42, proteinPer100g: 2.8, carbsPer100g: 7.6, fatPer100g: 0.2, fiberPer100g: 2.6, sugarPer100g: 4, sodiumMgPer100g: 4, icon: LucideIcons.bean),
  FoodDef(name: 'Butternut Squash', category: 'Vegetables', caloriesPer100g: 45, proteinPer100g: 1, carbsPer100g: 12, fatPer100g: 0.1, fiberPer100g: 2, sugarPer100g: 2.2, sodiumMgPer100g: 4),
  FoodDef(name: 'Pumpkin', category: 'Vegetables', caloriesPer100g: 26, proteinPer100g: 1, carbsPer100g: 6.5, fatPer100g: 0.1, fiberPer100g: 0.5, sugarPer100g: 2.8, sodiumMgPer100g: 1),
  FoodDef(name: 'Jicama', category: 'Vegetables', caloriesPer100g: 38, proteinPer100g: 0.7, carbsPer100g: 9, fatPer100g: 0.1, fiberPer100g: 4.9, sugarPer100g: 1.8, sodiumMgPer100g: 4),
  FoodDef(name: 'Rutabaga', category: 'Vegetables', caloriesPer100g: 37, proteinPer100g: 1.1, carbsPer100g: 8.6, fatPer100g: 0.2, fiberPer100g: 2.3, sugarPer100g: 4.5, sodiumMgPer100g: 12),
  FoodDef(name: 'Kohlrabi', category: 'Vegetables', caloriesPer100g: 27, proteinPer100g: 1.7, carbsPer100g: 6.2, fatPer100g: 0.1, fiberPer100g: 3.6, sugarPer100g: 2.6, sodiumMgPer100g: 20),

  // Grains
  FoodDef(name: 'White Rice (cooked)', category: 'Grains', caloriesPer100g: 130, proteinPer100g: 2.7, carbsPer100g: 28, fatPer100g: 0.3, fiberPer100g: 0.4, sugarPer100g: 0.1, sodiumMgPer100g: 1),
  FoodDef(name: 'Brown Rice (cooked)', category: 'Grains', caloriesPer100g: 123, proteinPer100g: 2.6, carbsPer100g: 26, fatPer100g: 1, fiberPer100g: 1.8, sugarPer100g: 0.4, sodiumMgPer100g: 5),
  FoodDef(name: 'Oats (dry)', category: 'Grains', caloriesPer100g: 389, proteinPer100g: 17, carbsPer100g: 66, fatPer100g: 7, fiberPer100g: 10.6, sugarPer100g: 1, sodiumMgPer100g: 2),
  FoodDef(name: 'Quinoa (cooked)', category: 'Grains', caloriesPer100g: 120, proteinPer100g: 4.4, carbsPer100g: 21, fatPer100g: 1.9, fiberPer100g: 2.8, sugarPer100g: 0.9, sodiumMgPer100g: 7),
  FoodDef(name: 'White Bread', category: 'Grains', caloriesPer100g: 265, proteinPer100g: 9, carbsPer100g: 49, fatPer100g: 3.2, fiberPer100g: 2.7, sugarPer100g: 5, sodiumMgPer100g: 490, icon: Icons.bakery_dining),
  FoodDef(name: 'Whole Wheat Bread', category: 'Grains', caloriesPer100g: 247, proteinPer100g: 13, carbsPer100g: 41, fatPer100g: 3.4, fiberPer100g: 6.8, sugarPer100g: 5.6, sodiumMgPer100g: 460, icon: LucideIcons.wheat),
  FoodDef(name: 'Pasta (cooked)', category: 'Grains', caloriesPer100g: 131, proteinPer100g: 5, carbsPer100g: 25, fatPer100g: 1.1, icon: Icons.ramen_dining),
  FoodDef(name: 'Couscous (cooked)', category: 'Grains', caloriesPer100g: 112, proteinPer100g: 3.8, carbsPer100g: 23, fatPer100g: 0.2),
  FoodDef(name: 'Bagel', category: 'Grains', caloriesPer100g: 250, proteinPer100g: 10, carbsPer100g: 49, fatPer100g: 1.5, icon: Icons.bakery_dining),
  FoodDef(name: 'Tortilla (flour)', category: 'Grains', caloriesPer100g: 312, proteinPer100g: 8, carbsPer100g: 51, fatPer100g: 8),
  FoodDef(name: 'Cornmeal', category: 'Grains', caloriesPer100g: 370, proteinPer100g: 8, carbsPer100g: 79, fatPer100g: 3.9),
  FoodDef(name: 'Barley (cooked)', category: 'Grains', caloriesPer100g: 123, proteinPer100g: 2.3, carbsPer100g: 28, fatPer100g: 0.4),
  FoodDef(name: 'Farro (cooked)', category: 'Grains', caloriesPer100g: 170, proteinPer100g: 6, carbsPer100g: 34, fatPer100g: 1.5, fiberPer100g: 5, sugarPer100g: 1, sodiumMgPer100g: 5),
  FoodDef(name: 'Bulgur (cooked)', category: 'Grains', caloriesPer100g: 83, proteinPer100g: 3.1, carbsPer100g: 18, fatPer100g: 0.2, fiberPer100g: 4.5, sugarPer100g: 0.1, sodiumMgPer100g: 5),
  FoodDef(name: 'Millet (cooked)', category: 'Grains', caloriesPer100g: 119, proteinPer100g: 3.5, carbsPer100g: 24, fatPer100g: 1, fiberPer100g: 1.3, sugarPer100g: 0, sodiumMgPer100g: 2),
  FoodDef(name: 'Rye Bread', category: 'Grains', caloriesPer100g: 259, proteinPer100g: 8.5, carbsPer100g: 48, fatPer100g: 3.3, fiberPer100g: 5.8, sugarPer100g: 4, sodiumMgPer100g: 603, icon: Icons.bakery_dining),
  FoodDef(name: 'Sourdough Bread', category: 'Grains', caloriesPer100g: 289, proteinPer100g: 11, carbsPer100g: 56, fatPer100g: 1.5, fiberPer100g: 2.6, sugarPer100g: 3, sodiumMgPer100g: 515, icon: Icons.bakery_dining),
  FoodDef(name: 'Pita Bread', category: 'Grains', caloriesPer100g: 275, proteinPer100g: 9, carbsPer100g: 55, fatPer100g: 1.2, fiberPer100g: 2.2, sugarPer100g: 1.5, sodiumMgPer100g: 536, icon: Icons.bakery_dining),
  FoodDef(name: 'Naan', category: 'Grains', caloriesPer100g: 310, proteinPer100g: 9, carbsPer100g: 50, fatPer100g: 8, fiberPer100g: 2, sugarPer100g: 4, sodiumMgPer100g: 500),
  FoodDef(name: 'Corn Flakes', category: 'Grains', caloriesPer100g: 357, proteinPer100g: 7.5, carbsPer100g: 84, fatPer100g: 0.4, fiberPer100g: 3, sugarPer100g: 8, sodiumMgPer100g: 660),
  FoodDef(name: 'Cream of Wheat (cooked)', category: 'Grains', caloriesPer100g: 60, proteinPer100g: 1.8, carbsPer100g: 13, fatPer100g: 0.2, fiberPer100g: 0.6, sugarPer100g: 0.1, sodiumMgPer100g: 3),
  FoodDef(name: 'Wild Rice (cooked)', category: 'Grains', caloriesPer100g: 101, proteinPer100g: 4, carbsPer100g: 21, fatPer100g: 0.3, fiberPer100g: 1.8, sugarPer100g: 0.7, sodiumMgPer100g: 3),

  // Protein
  FoodDef(name: 'Chicken Breast', category: 'Protein', caloriesPer100g: 165, proteinPer100g: 31, carbsPer100g: 0, fatPer100g: 3.6, sodiumMgPer100g: 74, icon: LucideIcons.drumstick),
  FoodDef(name: 'Chicken Thigh', category: 'Protein', caloriesPer100g: 209, proteinPer100g: 26, carbsPer100g: 0, fatPer100g: 10.9, icon: LucideIcons.drumstick),
  FoodDef(name: 'Beef (85% lean)', category: 'Protein', caloriesPer100g: 250, proteinPer100g: 26, carbsPer100g: 0, fatPer100g: 17, sodiumMgPer100g: 66, icon: LucideIcons.beef),
  FoodDef(name: 'Beef Sirloin Steak', category: 'Protein', caloriesPer100g: 206, proteinPer100g: 29, carbsPer100g: 0, fatPer100g: 9, icon: LucideIcons.beef),
  FoodDef(name: 'Pork Chop', category: 'Protein', caloriesPer100g: 231, proteinPer100g: 26, carbsPer100g: 0, fatPer100g: 14),
  FoodDef(name: 'Salmon', category: 'Protein', caloriesPer100g: 208, proteinPer100g: 20, carbsPer100g: 0, fatPer100g: 13, sodiumMgPer100g: 59, icon: LucideIcons.fish),
  FoodDef(name: 'Tuna (canned, water)', category: 'Protein', caloriesPer100g: 116, proteinPer100g: 26, carbsPer100g: 0, fatPer100g: 1, icon: LucideIcons.fish),
  FoodDef(name: 'Shrimp', category: 'Protein', caloriesPer100g: 99, proteinPer100g: 24, carbsPer100g: 0.2, fatPer100g: 0.3, icon: LucideIcons.shrimp),
  FoodDef(name: 'Cod', category: 'Protein', caloriesPer100g: 82, proteinPer100g: 18, carbsPer100g: 0, fatPer100g: 0.7, icon: LucideIcons.fish),
  FoodDef(name: 'Tilapia', category: 'Protein', caloriesPer100g: 96, proteinPer100g: 20, carbsPer100g: 0, fatPer100g: 1.7, icon: LucideIcons.fish),
  FoodDef(name: 'Egg (whole)', category: 'Protein', caloriesPer100g: 155, proteinPer100g: 13, carbsPer100g: 1.1, fatPer100g: 11, sugarPer100g: 1.1, sodiumMgPer100g: 124, icon: LucideIcons.egg),
  FoodDef(name: 'Egg Whites', category: 'Protein', caloriesPer100g: 52, proteinPer100g: 11, carbsPer100g: 0.7, fatPer100g: 0.2, icon: LucideIcons.egg),
  FoodDef(name: 'Turkey Breast', category: 'Protein', caloriesPer100g: 135, proteinPer100g: 30, carbsPer100g: 0, fatPer100g: 1, sodiumMgPer100g: 55, icon: LucideIcons.drumstick),
  FoodDef(name: 'Tofu', category: 'Protein', caloriesPer100g: 76, proteinPer100g: 8, carbsPer100g: 1.9, fatPer100g: 4.8),
  FoodDef(name: 'Tempeh', category: 'Protein', caloriesPer100g: 192, proteinPer100g: 20, carbsPer100g: 8, fatPer100g: 11),
  FoodDef(name: 'Bacon', category: 'Protein', caloriesPer100g: 541, proteinPer100g: 37, carbsPer100g: 1.4, fatPer100g: 42),
  FoodDef(name: 'Ham', category: 'Protein', caloriesPer100g: 145, proteinPer100g: 21, carbsPer100g: 1.5, fatPer100g: 5.5, icon: LucideIcons.ham),
  FoodDef(name: 'Lamb', category: 'Protein', caloriesPer100g: 294, proteinPer100g: 25, carbsPer100g: 0, fatPer100g: 21),
  FoodDef(name: 'Duck', category: 'Protein', caloriesPer100g: 337, proteinPer100g: 19, carbsPer100g: 0, fatPer100g: 28, sodiumMgPer100g: 63, icon: LucideIcons.drumstick),
  FoodDef(name: 'Venison', category: 'Protein', caloriesPer100g: 158, proteinPer100g: 30, carbsPer100g: 0, fatPer100g: 3.2, sodiumMgPer100g: 51),
  FoodDef(name: 'Bison', category: 'Protein', caloriesPer100g: 146, proteinPer100g: 21, carbsPer100g: 0, fatPer100g: 6.4, sodiumMgPer100g: 62, icon: LucideIcons.beef),
  FoodDef(name: 'Veal', category: 'Protein', caloriesPer100g: 172, proteinPer100g: 24, carbsPer100g: 0, fatPer100g: 8, sodiumMgPer100g: 87),
  FoodDef(name: 'Chicken Wing', category: 'Protein', caloriesPer100g: 203, proteinPer100g: 30, carbsPer100g: 0, fatPer100g: 8.1, sodiumMgPer100g: 84, icon: LucideIcons.drumstick),
  FoodDef(name: 'Chicken Drumstick', category: 'Protein', caloriesPer100g: 172, proteinPer100g: 28, carbsPer100g: 0, fatPer100g: 5.7, sodiumMgPer100g: 90, icon: LucideIcons.drumstick),
  FoodDef(name: 'Ground Turkey (93% lean)', category: 'Protein', caloriesPer100g: 176, proteinPer100g: 20, carbsPer100g: 0, fatPer100g: 10, sodiumMgPer100g: 82, icon: LucideIcons.drumstick),
  FoodDef(name: 'Ground Beef (90% lean)', category: 'Protein', caloriesPer100g: 176, proteinPer100g: 20, carbsPer100g: 0, fatPer100g: 10, sodiumMgPer100g: 66, icon: LucideIcons.beef),
  FoodDef(name: 'Ground Beef (80% lean)', category: 'Protein', caloriesPer100g: 254, proteinPer100g: 17, carbsPer100g: 0, fatPer100g: 20, sodiumMgPer100g: 66, icon: LucideIcons.beef),
  FoodDef(name: 'Pork Sausage', category: 'Protein', caloriesPer100g: 325, proteinPer100g: 17, carbsPer100g: 1.4, fatPer100g: 27, sodiumMgPer100g: 730),
  FoodDef(name: 'Chorizo', category: 'Protein', caloriesPer100g: 455, proteinPer100g: 24, carbsPer100g: 2.2, fatPer100g: 38, sodiumMgPer100g: 1235),
  FoodDef(name: 'Salami', category: 'Protein', caloriesPer100g: 336, proteinPer100g: 22, carbsPer100g: 1.6, fatPer100g: 26, sodiumMgPer100g: 1740),
  FoodDef(name: 'Pepperoni', category: 'Protein', caloriesPer100g: 494, proteinPer100g: 21, carbsPer100g: 2, fatPer100g: 44, sodiumMgPer100g: 1756),
  FoodDef(name: 'Halibut', category: 'Protein', caloriesPer100g: 111, proteinPer100g: 23, carbsPer100g: 0, fatPer100g: 1.8, sodiumMgPer100g: 59, icon: LucideIcons.fish),
  FoodDef(name: 'Mahi Mahi', category: 'Protein', caloriesPer100g: 109, proteinPer100g: 24, carbsPer100g: 0, fatPer100g: 0.9, sodiumMgPer100g: 88, icon: LucideIcons.fish),
  FoodDef(name: 'Sardines (canned)', category: 'Protein', caloriesPer100g: 208, proteinPer100g: 25, carbsPer100g: 0, fatPer100g: 11, sodiumMgPer100g: 307, icon: LucideIcons.fish),
  FoodDef(name: 'Anchovies', category: 'Protein', caloriesPer100g: 131, proteinPer100g: 20, carbsPer100g: 0, fatPer100g: 4.8, sodiumMgPer100g: 3668, icon: LucideIcons.fish),
  FoodDef(name: 'Crab', category: 'Protein', caloriesPer100g: 97, proteinPer100g: 19, carbsPer100g: 0, fatPer100g: 1.5, sodiumMgPer100g: 293),
  FoodDef(name: 'Lobster', category: 'Protein', caloriesPer100g: 89, proteinPer100g: 19, carbsPer100g: 0, fatPer100g: 0.9, sodiumMgPer100g: 296),
  FoodDef(name: 'Scallops', category: 'Protein', caloriesPer100g: 88, proteinPer100g: 17, carbsPer100g: 2.4, fatPer100g: 0.8, sodiumMgPer100g: 161),
  FoodDef(name: 'Mussels', category: 'Protein', caloriesPer100g: 172, proteinPer100g: 24, carbsPer100g: 7.4, fatPer100g: 4.5, sodiumMgPer100g: 369),
  FoodDef(name: 'Clams', category: 'Protein', caloriesPer100g: 148, proteinPer100g: 26, carbsPer100g: 5.1, fatPer100g: 1.9, sodiumMgPer100g: 601),
  FoodDef(name: 'Octopus', category: 'Protein', caloriesPer100g: 82, proteinPer100g: 15, carbsPer100g: 2.2, fatPer100g: 1, sodiumMgPer100g: 230),

  // Dairy
  FoodDef(name: 'Milk (whole)', category: 'Dairy', caloriesPer100g: 61, proteinPer100g: 3.2, carbsPer100g: 4.8, fatPer100g: 3.3, sugarPer100g: 5.1, sodiumMgPer100g: 43, icon: LucideIcons.milk),
  FoodDef(name: 'Milk (skim)', category: 'Dairy', caloriesPer100g: 34, proteinPer100g: 3.4, carbsPer100g: 5, fatPer100g: 0.1, icon: LucideIcons.milk),
  FoodDef(name: 'Greek Yogurt (plain)', category: 'Dairy', caloriesPer100g: 59, proteinPer100g: 10, carbsPer100g: 3.6, fatPer100g: 0.4, sugarPer100g: 3.6, sodiumMgPer100g: 36),
  FoodDef(name: 'Yogurt (plain, whole)', category: 'Dairy', caloriesPer100g: 61, proteinPer100g: 3.5, carbsPer100g: 4.7, fatPer100g: 3.3),
  FoodDef(name: 'Cheddar Cheese', category: 'Dairy', caloriesPer100g: 403, proteinPer100g: 25, carbsPer100g: 1.3, fatPer100g: 33, sugarPer100g: 0.5, sodiumMgPer100g: 621),
  FoodDef(name: 'Mozzarella', category: 'Dairy', caloriesPer100g: 280, proteinPer100g: 28, carbsPer100g: 3.1, fatPer100g: 17),
  FoodDef(name: 'Cottage Cheese', category: 'Dairy', caloriesPer100g: 98, proteinPer100g: 11, carbsPer100g: 3.4, fatPer100g: 4.3),
  FoodDef(name: 'Parmesan', category: 'Dairy', caloriesPer100g: 431, proteinPer100g: 38, carbsPer100g: 4.1, fatPer100g: 29),
  FoodDef(name: 'Butter', category: 'Dairy', caloriesPer100g: 717, proteinPer100g: 0.9, carbsPer100g: 0.1, fatPer100g: 81),
  FoodDef(name: 'Cream Cheese', category: 'Dairy', caloriesPer100g: 342, proteinPer100g: 6, carbsPer100g: 4.1, fatPer100g: 34),
  FoodDef(name: 'Sour Cream', category: 'Dairy', caloriesPer100g: 198, proteinPer100g: 2.4, carbsPer100g: 4.6, fatPer100g: 20),
  FoodDef(name: 'Swiss Cheese', category: 'Dairy', caloriesPer100g: 380, proteinPer100g: 27, carbsPer100g: 5.4, fatPer100g: 28, sodiumMgPer100g: 192),
  FoodDef(name: 'Feta Cheese', category: 'Dairy', caloriesPer100g: 264, proteinPer100g: 14, carbsPer100g: 4.1, fatPer100g: 21, sodiumMgPer100g: 917),
  FoodDef(name: 'Goat Cheese', category: 'Dairy', caloriesPer100g: 364, proteinPer100g: 22, carbsPer100g: 2.5, fatPer100g: 30, sodiumMgPer100g: 515),
  FoodDef(name: 'Ricotta', category: 'Dairy', caloriesPer100g: 174, proteinPer100g: 11, carbsPer100g: 3, fatPer100g: 13, sodiumMgPer100g: 84),
  FoodDef(name: 'Provolone', category: 'Dairy', caloriesPer100g: 351, proteinPer100g: 26, carbsPer100g: 2.1, fatPer100g: 27, sodiumMgPer100g: 876),
  FoodDef(name: 'Blue Cheese', category: 'Dairy', caloriesPer100g: 353, proteinPer100g: 21, carbsPer100g: 2.3, fatPer100g: 29, sodiumMgPer100g: 1146),
  FoodDef(name: 'Half and Half', category: 'Dairy', caloriesPer100g: 131, proteinPer100g: 3, carbsPer100g: 4.3, fatPer100g: 12, sodiumMgPer100g: 42),
  FoodDef(name: 'Whipped Cream', category: 'Dairy', caloriesPer100g: 257, proteinPer100g: 2.1, carbsPer100g: 12, fatPer100g: 22, sodiumMgPer100g: 44),
  FoodDef(name: 'Kefir', category: 'Dairy', caloriesPer100g: 41, proteinPer100g: 3.8, carbsPer100g: 4.5, fatPer100g: 1, sugarPer100g: 4.5, sodiumMgPer100g: 40, icon: LucideIcons.milk),
  FoodDef(name: 'Buttermilk', category: 'Dairy', caloriesPer100g: 40, proteinPer100g: 3.3, carbsPer100g: 4.8, fatPer100g: 0.9, sugarPer100g: 4.8, sodiumMgPer100g: 105, icon: LucideIcons.milk),

  // Legumes & Nuts
  FoodDef(name: 'Almonds', category: 'Legumes & Nuts', caloriesPer100g: 579, proteinPer100g: 21, carbsPer100g: 22, fatPer100g: 50, fiberPer100g: 12.5, sugarPer100g: 4.4, sodiumMgPer100g: 1),
  FoodDef(name: 'Peanuts', category: 'Legumes & Nuts', caloriesPer100g: 567, proteinPer100g: 26, carbsPer100g: 16, fatPer100g: 49, icon: LucideIcons.nut),
  FoodDef(name: 'Walnuts', category: 'Legumes & Nuts', caloriesPer100g: 654, proteinPer100g: 15, carbsPer100g: 14, fatPer100g: 65, icon: LucideIcons.nut),
  FoodDef(name: 'Cashews', category: 'Legumes & Nuts', caloriesPer100g: 553, proteinPer100g: 18, carbsPer100g: 30, fatPer100g: 44, icon: LucideIcons.nut),
  FoodDef(name: 'Peanut Butter', category: 'Legumes & Nuts', caloriesPer100g: 588, proteinPer100g: 25, carbsPer100g: 20, fatPer100g: 50, fiberPer100g: 6, sugarPer100g: 9, sodiumMgPer100g: 459, icon: LucideIcons.nut),
  FoodDef(name: 'Black Beans (cooked)', category: 'Legumes & Nuts', caloriesPer100g: 132, proteinPer100g: 9, carbsPer100g: 24, fatPer100g: 0.5, fiberPer100g: 8.7, sugarPer100g: 0.3, sodiumMgPer100g: 2, icon: LucideIcons.bean),
  FoodDef(name: 'Chickpeas (cooked)', category: 'Legumes & Nuts', caloriesPer100g: 164, proteinPer100g: 9, carbsPer100g: 27, fatPer100g: 2.6, icon: LucideIcons.bean),
  FoodDef(name: 'Lentils (cooked)', category: 'Legumes & Nuts', caloriesPer100g: 116, proteinPer100g: 9, carbsPer100g: 20, fatPer100g: 0.4, icon: LucideIcons.bean),
  FoodDef(name: 'Kidney Beans (cooked)', category: 'Legumes & Nuts', caloriesPer100g: 127, proteinPer100g: 9, carbsPer100g: 23, fatPer100g: 0.5, icon: LucideIcons.bean),
  FoodDef(name: 'Edamame', category: 'Legumes & Nuts', caloriesPer100g: 121, proteinPer100g: 11, carbsPer100g: 9, fatPer100g: 5, icon: LucideIcons.bean),
  FoodDef(name: 'Chia Seeds', category: 'Legumes & Nuts', caloriesPer100g: 486, proteinPer100g: 17, carbsPer100g: 42, fatPer100g: 31, icon: LucideIcons.sprout),
  FoodDef(name: 'Flaxseeds', category: 'Legumes & Nuts', caloriesPer100g: 534, proteinPer100g: 18, carbsPer100g: 29, fatPer100g: 42, icon: LucideIcons.sprout),
  FoodDef(name: 'Pistachios', category: 'Legumes & Nuts', caloriesPer100g: 560, proteinPer100g: 20, carbsPer100g: 28, fatPer100g: 45, fiberPer100g: 10, sugarPer100g: 8, sodiumMgPer100g: 1, icon: LucideIcons.nut),
  FoodDef(name: 'Macadamia Nuts', category: 'Legumes & Nuts', caloriesPer100g: 718, proteinPer100g: 7.9, carbsPer100g: 14, fatPer100g: 76, fiberPer100g: 8.6, sugarPer100g: 4.6, sodiumMgPer100g: 5, icon: LucideIcons.nut),
  FoodDef(name: 'Brazil Nuts', category: 'Legumes & Nuts', caloriesPer100g: 659, proteinPer100g: 14, carbsPer100g: 12, fatPer100g: 67, fiberPer100g: 7.5, sugarPer100g: 2.3, sodiumMgPer100g: 3, icon: LucideIcons.nut),
  FoodDef(name: 'Hazelnuts', category: 'Legumes & Nuts', caloriesPer100g: 628, proteinPer100g: 15, carbsPer100g: 17, fatPer100g: 61, fiberPer100g: 9.7, sugarPer100g: 4.3, sodiumMgPer100g: 0, icon: LucideIcons.nut),
  FoodDef(name: 'Pine Nuts', category: 'Legumes & Nuts', caloriesPer100g: 673, proteinPer100g: 14, carbsPer100g: 13, fatPer100g: 68, fiberPer100g: 3.7, sugarPer100g: 3.6, sodiumMgPer100g: 2, icon: LucideIcons.nut),
  FoodDef(name: 'Pecans', category: 'Legumes & Nuts', caloriesPer100g: 691, proteinPer100g: 9.2, carbsPer100g: 14, fatPer100g: 72, fiberPer100g: 9.6, sugarPer100g: 4, sodiumMgPer100g: 0, icon: LucideIcons.nut),
  FoodDef(name: 'Soybeans (cooked)', category: 'Legumes & Nuts', caloriesPer100g: 173, proteinPer100g: 16.6, carbsPer100g: 9.9, fatPer100g: 9, fiberPer100g: 6, sugarPer100g: 3, sodiumMgPer100g: 2, icon: LucideIcons.bean),
  FoodDef(name: 'Almond Butter', category: 'Legumes & Nuts', caloriesPer100g: 614, proteinPer100g: 21, carbsPer100g: 19, fatPer100g: 56, fiberPer100g: 10, sugarPer100g: 4.4, sodiumMgPer100g: 7, icon: LucideIcons.nut),
  FoodDef(name: 'Sunflower Seeds', category: 'Legumes & Nuts', caloriesPer100g: 584, proteinPer100g: 21, carbsPer100g: 20, fatPer100g: 51, fiberPer100g: 8.6, sugarPer100g: 2.6, sodiumMgPer100g: 9, icon: LucideIcons.nut),
  FoodDef(name: 'Pumpkin Seeds', category: 'Legumes & Nuts', caloriesPer100g: 559, proteinPer100g: 30, carbsPer100g: 11, fatPer100g: 49, fiberPer100g: 6, sugarPer100g: 1.4, sodiumMgPer100g: 7, icon: LucideIcons.nut),

  // Fats & Oils
  FoodDef(name: 'Olive Oil', category: 'Fats & Oils', caloriesPer100g: 884, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 100, sodiumMgPer100g: 2),
  FoodDef(name: 'Coconut Oil', category: 'Fats & Oils', caloriesPer100g: 862, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 100),
  FoodDef(name: 'Vegetable Oil', category: 'Fats & Oils', caloriesPer100g: 884, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 100),
  FoodDef(name: 'Mayonnaise', category: 'Fats & Oils', caloriesPer100g: 680, proteinPer100g: 1, carbsPer100g: 0.6, fatPer100g: 75),
  FoodDef(name: 'Avocado Oil', category: 'Fats & Oils', caloriesPer100g: 884, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 100, sodiumMgPer100g: 0),
  FoodDef(name: 'Sesame Oil', category: 'Fats & Oils', caloriesPer100g: 884, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 100, sodiumMgPer100g: 0),
  FoodDef(name: 'Ghee', category: 'Fats & Oils', caloriesPer100g: 900, proteinPer100g: 0.3, carbsPer100g: 0, fatPer100g: 100, sodiumMgPer100g: 2),
  FoodDef(name: 'Lard', category: 'Fats & Oils', caloriesPer100g: 902, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 100, sodiumMgPer100g: 0),

  // Beverages
  FoodDef(name: 'Orange Juice', category: 'Beverages', caloriesPer100g: 45, proteinPer100g: 0.7, carbsPer100g: 10, fatPer100g: 0.2, fiberPer100g: 0.2, sugarPer100g: 8.4, sodiumMgPer100g: 1, icon: Icons.local_drink),
  FoodDef(name: 'Apple Juice', category: 'Beverages', caloriesPer100g: 46, proteinPer100g: 0.1, carbsPer100g: 11, fatPer100g: 0.1, icon: Icons.local_drink),
  FoodDef(name: 'Coffee (black)', category: 'Beverages', caloriesPer100g: 2, proteinPer100g: 0.3, carbsPer100g: 0, fatPer100g: 0, sugarPer100g: 0, sodiumMgPer100g: 2, icon: LucideIcons.coffee),
  FoodDef(name: 'Soda (cola)', category: 'Beverages', caloriesPer100g: 41, proteinPer100g: 0, carbsPer100g: 10.6, fatPer100g: 0, sugarPer100g: 10.6, sodiumMgPer100g: 4, icon: LucideIcons.cupSoda),
  FoodDef(name: 'Beer', category: 'Beverages', caloriesPer100g: 43, proteinPer100g: 0.5, carbsPer100g: 3.6, fatPer100g: 0, icon: LucideIcons.beer),
  FoodDef(name: 'Wine (red)', category: 'Beverages', caloriesPer100g: 85, proteinPer100g: 0.1, carbsPer100g: 2.6, fatPer100g: 0, icon: LucideIcons.wine),
  FoodDef(name: 'Whey Protein Shake (water)', category: 'Beverages', caloriesPer100g: 103, proteinPer100g: 20, carbsPer100g: 3, fatPer100g: 1.5, icon: LucideIcons.glassWater),
  FoodDef(name: 'Almond Milk (unsweetened)', category: 'Beverages', caloriesPer100g: 15, proteinPer100g: 0.6, carbsPer100g: 0.6, fatPer100g: 1.2, sugarPer100g: 0, sodiumMgPer100g: 63, icon: LucideIcons.milk),
  FoodDef(name: 'Soy Milk', category: 'Beverages', caloriesPer100g: 33, proteinPer100g: 2.8, carbsPer100g: 1.8, fatPer100g: 1.6, sugarPer100g: 1, sodiumMgPer100g: 51, icon: LucideIcons.milk),
  FoodDef(name: 'Oat Milk', category: 'Beverages', caloriesPer100g: 47, proteinPer100g: 1, carbsPer100g: 7.5, fatPer100g: 1.5, sugarPer100g: 4.1, sodiumMgPer100g: 63, icon: LucideIcons.milk),
  FoodDef(name: 'Coconut Water', category: 'Beverages', caloriesPer100g: 19, proteinPer100g: 0.7, carbsPer100g: 3.7, fatPer100g: 0.2, sugarPer100g: 2.6, sodiumMgPer100g: 105, icon: LucideIcons.glassWater),
  FoodDef(name: 'Sports Drink', category: 'Beverages', caloriesPer100g: 24, proteinPer100g: 0, carbsPer100g: 6, fatPer100g: 0, sugarPer100g: 5.9, sodiumMgPer100g: 41, icon: LucideIcons.cupSoda),
  FoodDef(name: 'Energy Drink', category: 'Beverages', caloriesPer100g: 45, proteinPer100g: 0.5, carbsPer100g: 11, fatPer100g: 0, sugarPer100g: 11, sodiumMgPer100g: 40, icon: LucideIcons.cupSoda),
  FoodDef(name: 'Tea (unsweetened)', category: 'Beverages', caloriesPer100g: 1, proteinPer100g: 0, carbsPer100g: 0.3, fatPer100g: 0, sugarPer100g: 0, sodiumMgPer100g: 3),
  FoodDef(name: 'Diet Soda', category: 'Beverages', caloriesPer100g: 0, proteinPer100g: 0, carbsPer100g: 0.1, fatPer100g: 0, sugarPer100g: 0, sodiumMgPer100g: 21, icon: LucideIcons.cupSoda),

  // Snacks & Sweets
  FoodDef(name: 'Dark Chocolate', category: 'Snacks & Sweets', caloriesPer100g: 546, proteinPer100g: 7.8, carbsPer100g: 46, fatPer100g: 31, fiberPer100g: 11, sugarPer100g: 24, sodiumMgPer100g: 20),
  FoodDef(name: 'Milk Chocolate', category: 'Snacks & Sweets', caloriesPer100g: 535, proteinPer100g: 7.7, carbsPer100g: 59, fatPer100g: 30),
  FoodDef(name: 'Potato Chips', category: 'Snacks & Sweets', caloriesPer100g: 536, proteinPer100g: 7, carbsPer100g: 53, fatPer100g: 35, fiberPer100g: 4.4, sugarPer100g: 0.3, sodiumMgPer100g: 525),
  FoodDef(name: 'Popcorn (air-popped)', category: 'Snacks & Sweets', caloriesPer100g: 387, proteinPer100g: 13, carbsPer100g: 78, fatPer100g: 4.5, icon: LucideIcons.popcorn),
  FoodDef(name: 'Granola Bar', category: 'Snacks & Sweets', caloriesPer100g: 471, proteinPer100g: 10, carbsPer100g: 64, fatPer100g: 20),
  FoodDef(name: 'Honey', category: 'Snacks & Sweets', caloriesPer100g: 304, proteinPer100g: 0.3, carbsPer100g: 82, fatPer100g: 0, fiberPer100g: 0.2, sugarPer100g: 82, sodiumMgPer100g: 4),
  FoodDef(name: 'White Sugar', category: 'Snacks & Sweets', caloriesPer100g: 387, proteinPer100g: 0, carbsPer100g: 100, fatPer100g: 0, sugarPer100g: 100, sodiumMgPer100g: 0),
  FoodDef(name: 'Ice Cream', category: 'Snacks & Sweets', caloriesPer100g: 207, proteinPer100g: 3.5, carbsPer100g: 24, fatPer100g: 11, icon: LucideIcons.iceCream),
  FoodDef(name: 'Pretzels', category: 'Snacks & Sweets', caloriesPer100g: 380, proteinPer100g: 10, carbsPer100g: 79, fatPer100g: 2.6),
  FoodDef(name: 'Donut', category: 'Snacks & Sweets', caloriesPer100g: 452, proteinPer100g: 4.9, carbsPer100g: 51, fatPer100g: 25, icon: LucideIcons.donut),
  FoodDef(name: 'Protein Bar', category: 'Snacks & Sweets', caloriesPer100g: 380, proteinPer100g: 30, carbsPer100g: 38, fatPer100g: 12, fiberPer100g: 6, sugarPer100g: 20, sodiumMgPer100g: 250),
  FoodDef(name: 'Trail Mix', category: 'Snacks & Sweets', caloriesPer100g: 462, proteinPer100g: 14, carbsPer100g: 45, fatPer100g: 29, fiberPer100g: 6, sugarPer100g: 30, sodiumMgPer100g: 145, icon: LucideIcons.nut),
  FoodDef(name: 'Rice Cakes', category: 'Snacks & Sweets', caloriesPer100g: 387, proteinPer100g: 8.2, carbsPer100g: 82, fatPer100g: 2.8, fiberPer100g: 3.6, sugarPer100g: 0.4, sodiumMgPer100g: 17),
  FoodDef(name: 'Crackers (saltine)', category: 'Snacks & Sweets', caloriesPer100g: 421, proteinPer100g: 9, carbsPer100g: 74, fatPer100g: 10, fiberPer100g: 3, sugarPer100g: 1, sodiumMgPer100g: 1000),
  FoodDef(name: 'Waffle', category: 'Snacks & Sweets', caloriesPer100g: 291, proteinPer100g: 7.9, carbsPer100g: 43, fatPer100g: 9.6, fiberPer100g: 1.5, sugarPer100g: 8, sodiumMgPer100g: 615),
  FoodDef(name: 'Pancake', category: 'Snacks & Sweets', caloriesPer100g: 227, proteinPer100g: 6.4, carbsPer100g: 28, fatPer100g: 10, fiberPer100g: 0.9, sugarPer100g: 6.4, sodiumMgPer100g: 439),
  FoodDef(name: 'Muffin (blueberry)', category: 'Snacks & Sweets', caloriesPer100g: 377, proteinPer100g: 6, carbsPer100g: 55, fatPer100g: 15, fiberPer100g: 1.7, sugarPer100g: 30, sodiumMgPer100g: 380),
  FoodDef(name: 'Croissant', category: 'Snacks & Sweets', caloriesPer100g: 406, proteinPer100g: 8.2, carbsPer100g: 46, fatPer100g: 21, fiberPer100g: 2.6, sugarPer100g: 8, sodiumMgPer100g: 447, icon: LucideIcons.croissant),
  FoodDef(name: 'Cake (frosted, chocolate)', category: 'Snacks & Sweets', caloriesPer100g: 371, proteinPer100g: 4.2, carbsPer100g: 53, fatPer100g: 16, fiberPer100g: 1.7, sugarPer100g: 40, sodiumMgPer100g: 297, icon: LucideIcons.cake),
  FoodDef(name: 'Chocolate Chip Cookie', category: 'Snacks & Sweets', caloriesPer100g: 488, proteinPer100g: 5.4, carbsPer100g: 65, fatPer100g: 24, fiberPer100g: 2.1, sugarPer100g: 39, sodiumMgPer100g: 358, icon: LucideIcons.cookie),
  FoodDef(name: 'Jam / Jelly', category: 'Snacks & Sweets', caloriesPer100g: 278, proteinPer100g: 0.4, carbsPer100g: 69, fatPer100g: 0.1, fiberPer100g: 0.6, sugarPer100g: 51, sodiumMgPer100g: 25),
  FoodDef(name: 'Maple Syrup', category: 'Snacks & Sweets', caloriesPer100g: 260, proteinPer100g: 0, carbsPer100g: 67, fatPer100g: 0.2, fiberPer100g: 0, sugarPer100g: 60, sodiumMgPer100g: 12),
];
