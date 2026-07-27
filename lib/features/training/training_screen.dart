import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/sharing/workout_share.dart';
import '../../core/theme/app_theme.dart';
import '../../core/training/weight_series.dart';
import '../../core/units/units.dart';
import '../../models/workout_session.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/training_repository.dart';
import '../../widgets/action_card.dart';
import '../../widgets/activity_week_strip.dart';
import '../../widgets/import_code_dialog.dart';
import '../../widgets/share_code_sheet.dart';
import 'day_templates_screen.dart';
import 'log_weight_sheet.dart';
import 'session_detail_screen.dart';
import 'split_selection_screen.dart';
import 'weight_history_screen.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  Future<void> _openCustomDay(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom day'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Day name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DayTemplatesScreen(dayName: name)),
      );
    }
  }

  void _openDay(
      BuildContext context, List<WorkoutSession> sessions, DateTime date) {
    for (final session in sessions) {
      if (isSameDay(session.date, date)) {
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => SessionDetailScreen(session: session)),
        );
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<TrainingRepository>();

    if (repo.isLoaded && !repo.hasSplit) {
      return const SplitSelectionScreen();
    }

    final weekDays = [
      for (final date in lastSevenDays())
        ActivityDay(
          date: date,
          primaryActive: repo.sessions.any((s) => isSameDay(s.date, date)),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training'),
        actions: [
          IconButton(
            tooltip: 'Change split',
            icon: const Icon(Icons.tune),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SplitSelectionScreen()),
            ),
          ),
        ],
      ),
      body: !repo.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                ActivityWeekStrip(
                  days: weekDays,
                  primaryColor: AppColors.training,
                  onDayTap: (date) => _openDay(context, repo.sessions, date),
                ),
                const SizedBox(height: 16),
                _WeightCard(repo: repo),
                const SizedBox(height: 28),
                Text(
                  'Log a workout',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                for (final day in repo.split!.dayNames)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ActionCard(
                      icon: Icons.fitness_center,
                      title: day,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DayTemplatesScreen(dayName: day),
                        ),
                      ),
                    ),
                  ),
                Center(
                  child: TextButton(
                    onPressed: () => _openCustomDay(context),
                    child: const Text('Custom day'),
                  ),
                ),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => showShareCodeSheet(
                          context,
                          title: 'Share my split',
                          code: encodeSplitBundle(repo.split!, repo.templates),
                          shareSubject: 'My ${repo.split!.name} split',
                        ),
                        child: const Text('Share my split'),
                      ),
                      TextButton(
                        onPressed: () => showImportCodeDialog(context),
                        child: const Text('Import shared workout'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Recent workouts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (repo.sessions.isEmpty)
                  const _EmptyState(
                    icon: Icons.fitness_center,
                    message: 'No workouts logged yet',
                  )
                else
                  ...repo.sessions.map((s) => _SessionTile(session: s)),
              ],
            ),
    );
  }
}

class _WeightCard extends StatelessWidget {
  final TrainingRepository repo;

  const _WeightCard({required this.repo});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileRepository>().profile;
    final unitSystem = context.watch<SettingsRepository>().unitSystem;
    final points =
        buildWeightSeries(profile: profile, weightEntries: repo.weightEntries);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const WeightHistoryScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Weight',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: scheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          repo.latestWeightKg != null
                              ? Units.formatWeight(
                                  repo.latestWeightKg!, unitSystem)
                              : profile != null
                                  ? '${Units.formatWeight(profile.weightKg, unitSystem)} (starting)'
                                  : 'No entries yet',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => showLogWeightSheet(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Log'),
                  ),
                ],
              ),
              if (points.length >= 2) ...[
                const SizedBox(height: 20),
                SizedBox(
                  height: 140,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineTouchData: const LineTouchData(enabled: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (var i = 0; i < points.length; i++)
                              FlSpot(
                                i.toDouble(),
                                unitSystem == UnitSystem.metric
                                    ? points[i].weightKg
                                    : Units.kgToLbs(points[i].weightKg),
                              ),
                          ],
                          isCurved: true,
                          color: scheme.primary,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: scheme.primary.withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final WorkoutSession session;

  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SessionDetailScreen(session: session),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      DateFormat.MMMd().format(session.date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  session.dayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                if (session.exercises.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    session.exercises
                        .map((e) => '${e.exerciseName} ${e.sets.length}x')
                        .join(' · '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            icon,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
