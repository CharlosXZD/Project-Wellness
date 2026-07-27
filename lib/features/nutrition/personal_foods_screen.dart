import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/sharing/library_share.dart';
import '../../repositories/nutrition_repository.dart';
import '../../repositories/training_repository.dart';
import '../../widgets/action_card.dart';
import '../../widgets/import_code_dialog.dart';
import '../../widgets/rect_button.dart';
import '../../widgets/share_code_sheet.dart';
import 'personal_food_editor_screen.dart';
import 'scan_screen.dart';
import 'scanned_products_screen.dart';

/// Lists this user's personal (custom) foods — create, edit, or delete.
/// Reached from Settings; the "My Foods" chip in the food picker surfaces
/// the same list when logging or building a recipe.
class PersonalFoodsScreen extends StatelessWidget {
  const PersonalFoodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final foods = context.watch<NutritionRepository>().personalFoods;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Personal Foods')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              'Your personal foods',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              "Add anything that isn't in the food library, with its own calories and macros per 100g.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            for (final food in foods)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ActionCard(
                  icon: Icons.restaurant,
                  title: food.name,
                  subtitle:
                      '${food.caloriesPer100g.toStringAsFixed(0)} kcal / 100g · ${food.category}',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PersonalFoodEditorScreen(existing: food),
                    ),
                  ),
                ),
              ),
            RectButton(
              icon: Icons.add_circle_outline,
              title: 'New personal food',
              outlined: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const PersonalFoodEditorScreen()),
              ),
            ),
            const SizedBox(height: 12),
            RectButton(
              icon: Icons.qr_code_scanner,
              title: 'Scan to add',
              subtitle:
                  'Barcode or nutrition label — prefills the form for you',
              outlined: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const ScanScreen(mode: ScanResultMode.savePersonalFood),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ScannedProductsScreen()),
                ),
                child: const Text('Or pick from previously scanned'),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.ios_share, size: 18),
                    label: const Text('Export my library'),
                    onPressed: () => showShareCodeSheet(
                      context,
                      title: 'Export my library',
                      code: encodeLibraryBundle(
                        exercises:
                            context.read<TrainingRepository>().customExercises,
                        foods: foods,
                      ),
                      shareSubject: 'My personal exercises & foods',
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Import shared library'),
                    onPressed: () => showImportCodeDialog(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
