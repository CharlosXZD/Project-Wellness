import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/workout_template.dart';
import '../../repositories/active_workout_repository.dart';
import '../../repositories/training_repository.dart';
import 'active_workout_screen.dart';

/// 5-4-3-2-1-GO countdown shown right before a workout starts, purely for
/// the gamified "get ready" moment the user asked for — on GO it replaces
/// itself with [ActiveWorkoutScreen] so the back button can't return here.
/// Tapping the screen 3 times in quick succession skips straight to the
/// workout, for anyone who doesn't want to wait it out.
class WorkoutCountdownScreen extends StatefulWidget {
  final WorkoutTemplate template;

  const WorkoutCountdownScreen({super.key, required this.template});

  @override
  State<WorkoutCountdownScreen> createState() => _WorkoutCountdownScreenState();
}

class _WorkoutCountdownScreenState extends State<WorkoutCountdownScreen> {
  static const _ticks = ['5', '4', '3', '2', '1', 'GO'];
  static const _skipTapThreshold = 3;
  static const _skipTapWindow = Duration(milliseconds: 800);

  int _index = 0;
  Timer? _timer;
  int _tapCount = 0;
  DateTime? _firstTapAt;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer timer) {
    if (_index >= _ticks.length - 1) {
      timer.cancel();
      _goToActiveWorkout();
      return;
    }
    setState(() => _index++);
  }

  Future<void> _goToActiveWorkout() async {
    if (_navigated) return;
    _navigated = true;
    _timer?.cancel();

    await context.read<ActiveWorkoutRepository>().start(
          widget.template,
          context.read<TrainingRepository>(),
        );
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
    );
  }

  void _onTap() {
    final now = DateTime.now();
    if (_firstTapAt == null || now.difference(_firstTapAt!) > _skipTapWindow) {
      _firstTapAt = now;
      _tapCount = 1;
      return;
    }
    _tapCount++;
    if (_tapCount >= _skipTapThreshold) _goToActiveWorkout();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isGo = _ticks[_index] == 'GO';

    return Scaffold(
      backgroundColor: scheme.primary,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Text(
              _ticks[_index],
              key: ValueKey(_index),
              style: TextStyle(
                fontSize: isGo ? 96 : 140,
                fontWeight: FontWeight.bold,
                color: scheme.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
