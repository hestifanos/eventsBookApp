// lib/screens/event_detail_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../services/event_service.dart';
import '../services/notification_service.dart';
import '../models/event.dart';

class EventDetailPage extends StatefulWidget {
  final String eventId;

  const EventDetailPage({super.key, required this.eventId});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final _eventService = EventService();
  Event? _event;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final event = await _eventService.getEvent(widget.eventId);
    if (!mounted) return;
    setState(() {
      _event = event;
      _loading = false;
    });
  }

  /// Parse strings like "Nov 22, 3:00 PM" or "dec 23, 9:30 pm" into a DateTime.
  /// - Uses current year.
  /// - If that datetime is already in the past, assumes it's next year.
  DateTime? _parseEventDateTime(String text) {
    final raw = text.trim();
    if (raw.isEmpty) return null;

    // Normalize spaces
    var normalized = raw.replaceAll(RegExp(r'\s+'), ' ');

    // Normalize AM/PM
    normalized = normalized.replaceAllMapped(
      RegExp(r'\b(am|pm)\b', caseSensitive: false),
          (m) => m.group(0)!.toUpperCase(),
    );

    // Capitalize first letter for e.g. "nov 23" -> "Nov 23"
    if (normalized.isNotEmpty) {
      normalized = normalized[0].toUpperCase() + normalized.substring(1);
    }

    final now = DateTime.now();

    // Supported formats
    final formats = <DateFormat>[
      DateFormat('MMM d, h:mm a'), // "Nov 23, 3:00 PM"
      DateFormat('MMM d, h a'),    // "Nov 23, 3 PM"
      DateFormat('MM/dd/yyyy'),    // "12/12/2025"
      DateFormat('dd/MM/yyyy'),    // "12/12/2025"
      DateFormat('yyyy-MM-dd'),    // "2025-12-12"
    ];

    for (final f in formats) {
      try {
        final parsed = f.parseLoose(normalized);

        DateTime dt;

        // If the pattern contains a month name (MMM)
        if (f.pattern?.contains('MMM') == true) {
          // Month-name formats usually don't include year
          dt = DateTime(
            now.year,
            parsed.month,
            parsed.day,
            parsed.hour,
            parsed.minute,
          );
        } else {
          // Numeric formats → use parsed year
          final hour = (parsed.hour == 0 && parsed.minute == 0)
              ? 9 // default to 9 AM if time not provided
              : parsed.hour;

          dt = DateTime(
            parsed.year,
            parsed.month,
            parsed.day,
            hour,
            parsed.minute,
          );
        }

        // If result is before now, assume next year
        if (dt.isBefore(now)) {
          dt = DateTime(
            dt.year + 1,
            dt.month,
            dt.day,
            dt.hour,
            dt.minute,
          );
        }

        return dt;
      } catch (_) {
        // try next format
      }
    }

    return null; // nothing matched
  }



  Future<void> _setReminder() async {
    final e = _event;
    if (e == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event not loaded yet')),
      );
      return;
    }

    final dt = _parseEventDateTime(e.dateTimeText);
    if (dt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not understand the event date/time. '
                'Please edit the event and pick the time using the date/time picker.',
          ),
        ),
      );
      return;
    }

    await NotificationService.scheduleEventReminder(
      id: e.id,
      title: 'Upcoming event: ${e.title}',
      body: 'Starts at ${e.dateTimeText}',
      eventTime: dt,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reminder set for ${DateFormat('MMM d, h:mm a').format(dt.subtract(const Duration(hours: 2)))}',
        ),
      ),
    );
  }

  Future<void> _openInMaps() async {
    final e = _event;
    if (e == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event not loaded yet')),
      );
      return;
    }

    Uri? uri;

    if (e.latitude != null && e.longitude != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${e.latitude},${e.longitude}',
      );
    } else if (e.locationName.isNotEmpty) {
      final query = Uri.encodeComponent(e.locationName);
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$query',
      );
    }

    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No location information for this event')),
      );
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  Future<void> _openVideo() async {
    final e = _event;
    if (e == null || e.videoUrl == null || e.videoUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No video for this event')),
      );
      return;
    }
    final uri = Uri.parse(e.videoUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open video')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_event == null) {
      return const Scaffold(
        body: Center(child: Text('Event not found')),
      );
    }

    final e = _event!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(e.title),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4C1D95), Color(0xFF6D28D9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF7F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media area: image first, otherwise a video button
            if (e.imageUrl != null && e.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  e.imageUrl!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else if (e.videoUrl != null && e.videoUrl!.isNotEmpty)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.play_circle_fill,
                      size: 50,
                      color: Color(0xFF6D28D9),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This event has a video',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _openVideo,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(
                            color: const Color(0xFF6D28D9).withOpacity(0.2),
                          ),
                        ),
                      ),
                      child: const Text(
                        'Open event video',
                        style: TextStyle(
                          color: Color(0xFF6D28D9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if ((e.imageUrl != null && e.imageUrl!.isNotEmpty) ||
                (e.videoUrl != null && e.videoUrl!.isNotEmpty))
              const SizedBox(height: 20),

            // Main info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hosted by: ${e.hostName}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When: ${e.dateTimeText}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Where: ${e.locationName}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    e.description,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  // Clean, non-overflowing buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openInMaps,
                          icon: const Icon(Icons.map_outlined),
                          label: const Text(
                            'Open in Maps',               // shorter label so it doesn't wrap
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            minimumSize: const Size(0, 48), // consistent height
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _setReminder,
                          icon: const Icon(Icons.notifications_active_outlined),
                          label: const Text(
                            'Set reminder',
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4C1D95),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                  ,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
