import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/navigation/active_workout_route_observer.dart';
import '../core/training/duration_format.dart';
import '../features/training/active_workout_screen.dart';
import '../repositories/active_workout_repository.dart';

/// Global floating bar shown above whatever screen is currently on top
/// (wired into `MaterialApp.builder` in `app.dart`) whenever a workout is
/// in progress but its full screen isn't the one visible right now — lets
/// the user check Nutrition, another workout day, or Medals mid-workout
/// without losing their place, and pause the clock if they need to step
/// away. Renders nothing when there's no active workout, or when
/// `ActiveWorkoutScreen` itself is already showing.
///
/// Drag it up or down to reposition — the offset lives only for this app
/// session (resets to the default bottom position on next launch).
class ActiveWorkoutBar extends StatefulWidget {
  const ActiveWorkoutBar({super.key});

  @override
  State<ActiveWorkoutBar> createState() => _ActiveWorkoutBarState();
}

class _ActiveWorkoutBarState extends State<ActiveWorkoutBar> {
  double _liftFromBottom = 0;

  void _onDragUpdate(DragUpdateDetails details, double maxLift) {
    setState(() {
      _liftFromBottom = (_liftFromBottom - details.delta.dy).clamp(0, maxLift);
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ActiveWorkoutRepository>();
    if (!repo.hasActiveWorkout || repo.isScreenVisible) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    // Leaves room for the status bar at the top and the bar's own height
    // at the bottom, so it can't be dragged off either edge of the screen.
    final maxLift = MediaQuery.of(context).size.height - 200;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + _liftFromBottom),
        child: GestureDetector(
          onVerticalDragUpdate: (details) => _onDragUpdate(details, maxLift),
          child: Material(
            color: scheme.primaryContainer,
            elevation: 4,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => rootNavigatorKey.currentState?.push(
                MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                repo.isPaused ? Icons.pause_circle_outline : Icons.fitness_center,
                                size: 16,
                                color: scheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  repo.template?.name ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: scheme.onPrimaryContainer,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formatElapsedDuration(repo.elapsed),
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: scheme.onPrimaryContainer,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: repo.progressFraction,
                              minHeight: 4,
                              backgroundColor: scheme.onPrimaryContainer.withValues(alpha: 0.16),
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: repo.isPaused ? repo.resume : repo.pause,
                      icon: Icon(
                        repo.isPaused ? Icons.play_arrow : Icons.pause,
                        color: scheme.onPrimaryContainer,
                      ),
                      tooltip: repo.isPaused ? 'Resume' : 'Pause',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
