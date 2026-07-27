import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/food_library.dart';
import '../../models/food_def.dart';
import '../../models/ingredient.dart';
import '../../repositories/nutrition_repository.dart';
import '../../widgets/create_food_card.dart';
import 'add_food_sheet.dart';
import 'log_food_amount_sheet.dart';
import 'personal_food_editor_screen.dart';

const _myFoodsCategory = 'My Foods';

/// Search-and-pick screen for the food library. Normally selecting a food
/// opens the grams sheet, which logs it to today. When [pickerMode] is set,
/// selecting (or manually adding) a food instead pops the screen with the
/// resulting [Ingredient] — used by the recipe builder.
class FoodPickerScreen extends StatefulWidget {
  final bool pickerMode;

  const FoodPickerScreen({super.key, this.pickerMode = false});

  @override
  State<FoodPickerScreen> createState() => _FoodPickerScreenState();
}

class _FoodPickerScreenState extends State<FoodPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _chipCategories {
    final hasPersonal = context.watch<NutritionRepository>().personalFoods.isNotEmpty;
    return ['All', if (hasPersonal) _myFoodsCategory, ...foodCategories];
  }

  List<FoodDef> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    final personalDefs = context
        .watch<NutritionRepository>()
        .personalFoods
        .map((f) => f.toFoodDef());
    if (_selectedCategory == _myFoodsCategory) {
      return personalDefs
          .where((f) => query.isEmpty || f.name.toLowerCase().contains(query))
          .toList();
    }
    final all = [...foodLibrary, ...personalDefs];
    return all.where((f) {
      final matchesCategory =
          _selectedCategory == 'All' || f.category == _selectedCategory;
      final matchesQuery = query.isEmpty || f.name.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  Future<void> _selectFood(FoodDef food) async {
    final result = await showLogFoodAmountSheet(context, food, pickerMode: widget.pickerMode);
    if (!mounted) return;
    if (widget.pickerMode && result is Ingredient) {
      Navigator.of(context).pop(result);
    } else if (result == true) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _createPersonalFood() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonalFoodEditorScreen(
          initialName: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filtered = _filtered;
    final noMatches = filtered.isEmpty && _searchController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Search food')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search foods',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _searchController.clear,
                        tooltip: 'Clear search',
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _chipCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _chipCategories[index];
                final isSelected = category == _selectedCategory;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedCategory = category),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: noMatches
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No food called "${_searchController.text.trim()}"',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final result = await showAddFoodSheet(
                                context,
                                initialName: _searchController.text.trim(),
                                pickerMode: widget.pickerMode,
                              );
                              if (!context.mounted) return;
                              if (widget.pickerMode && result is Ingredient) {
                                Navigator.of(context).pop(result);
                              } else if (result == true) {
                                Navigator.of(context).pop();
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add manually instead'),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _createPersonalFood,
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Or save it as a personal food for next time'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: filtered.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return CreateFoodCard(onTap: _createPersonalFood);
                      }
                      final food = filtered[index - 1];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _selectFood(food),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    iconForFood(food),
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          food.name,
                                          style: Theme.of(context).textTheme.bodyLarge,
                                        ),
                                        Text(
                                          '${food.caloriesPer100g.toStringAsFixed(0)} kcal / 100g',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: scheme.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: noMatches
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextButton.icon(
                onPressed: () async {
                  final result = await showAddFoodSheet(
                    context,
                    initialName: _searchController.text.trim(),
                    pickerMode: widget.pickerMode,
                  );
                  if (!context.mounted) return;
                  if (widget.pickerMode && result is Ingredient) {
                    Navigator.of(context).pop(result);
                  } else if (result == true) {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text("Can't find it? Add manually"),
              ),
            ),
    );
  }
}
