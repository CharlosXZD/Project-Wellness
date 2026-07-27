import 'package:flutter/material.dart';

/// Like [RectButton] but bigger, and with room for a row of small in-card
/// icon-only actions (edit/share) below the header instead of a separate
/// text link floating outside the card. Used for entities that carry their
/// own secondary actions — workout templates, saved snacks/recipes — not a
/// replacement for [RectButton]'s plain nav rows (Settings' Edit Profile,
/// Reminders, etc.), which have no secondary actions to place.
class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final String playTooltip;
  final String editTooltip;
  final String shareTooltip;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.onPlay,
    this.onEdit,
    this.onShare,
    this.playTooltip = 'Start',
    this.editTooltip = 'Edit',
    this.shareTooltip = 'Share',
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasActions = onPlay != null || onEdit != null || onShare != null;

    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: hasActions
                ? const BorderRadius.vertical(top: Radius.circular(20))
                : BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.fromLTRB(22, 22, 22, hasActions ? 12 : 22),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: scheme.onPrimary, size: 26),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: Theme.of(context).textTheme.titleMedium),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (hasActions)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 12, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onPlay != null)
                    IconButton(
                      icon: const Icon(Icons.play_arrow, size: 20),
                      onPressed: onPlay,
                      tooltip: playTooltip,
                      visualDensity: VisualDensity.compact,
                      color: scheme.primary,
                    ),
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: onEdit,
                      tooltip: editTooltip,
                      visualDensity: VisualDensity.compact,
                      color: scheme.onSurfaceVariant,
                    ),
                  if (onShare != null)
                    IconButton(
                      icon: const Icon(Icons.ios_share, size: 18),
                      onPressed: onShare,
                      tooltip: shareTooltip,
                      visualDensity: VisualDensity.compact,
                      color: scheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
