import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/nutrition_repository.dart';
import '../../widgets/rect_button.dart';
import 'add_supplement_sheet.dart';

class SupplementsScreen extends StatelessWidget {
  const SupplementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<NutritionRepository>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Supplements')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            if (repo.supplements.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.medication_outlined, size: 40, color: scheme.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text(
                      'Nothing added yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              )
            else
              for (final supplement in repo.supplements)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Dismissible(
                    key: ValueKey(supplement.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
                    ),
                    onDismissed: (_) => context
                        .read<NutritionRepository>()
                        .deleteSupplement(supplement.id),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.medication_outlined, color: scheme.primary),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    supplement.name,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    supplement.notes == null
                                        ? supplement.dosage
                                        : '${supplement.dosage} · ${supplement.notes}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            RectButton(
              icon: Icons.add_circle_outline,
              title: 'Add supplement',
              outlined: true,
              onTap: () => showAddSupplementSheet(context),
            ),
          ],
        ),
      ),
    );
  }
}
