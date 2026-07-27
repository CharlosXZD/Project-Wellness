import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Icon button that opens a YouTube form-tutorial link for an exercise.
/// Renders nothing when [videoUrl] is null (e.g. custom, user-added exercises
/// or library exercises without a verified video in EXERCISE_VIDEO_REGISTRY.md).
class WatchFormVideoButton extends StatelessWidget {
  final String? videoUrl;
  final double size;
  final String? label;

  const WatchFormVideoButton({
    super.key,
    required this.videoUrl,
    this.size = 22,
    this.label,
  });

  Future<void> _open(BuildContext context) async {
    final url = videoUrl;
    if (url == null) return;
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open video')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = videoUrl;
    if (url == null) return const SizedBox.shrink();

    final label = this.label;
    if (label != null) {
      return FilledButton.tonalIcon(
        onPressed: () => _open(context),
        icon: Icon(Icons.smart_display_outlined, size: size),
        label: Text(label),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: () => _open(context),
      icon: Icon(Icons.smart_display_outlined, size: size, color: scheme.primary),
      tooltip: 'Watch form video',
      visualDensity: VisualDensity.compact,
    );
  }
}
