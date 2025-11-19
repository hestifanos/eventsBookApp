
import 'package:flutter/material.dart';
import '../models/event.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final Widget? trailing;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hasImage =
        event.imageUrl != null && event.imageUrl!.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Row(
          children: [
            // image or icon
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: hasImage
                  ? Image.network(
                event.imageUrl!.trim(),
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackIcon(theme),
              )
                  : _fallbackIcon(theme),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${event.locationName} • ${event.dateTimeText}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _fallbackIcon(ThemeData theme) {
    return Container(
      width: 90,
      height: 90,
      color: theme.colorScheme.primary.withOpacity(0.08),
      child: Icon(
        Icons.event,
        size: 32,
        color: theme.colorScheme.primary,
      ),
    );
  }
}
