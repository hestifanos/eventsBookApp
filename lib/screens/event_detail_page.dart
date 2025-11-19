
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../services/notification_service.dart';

class EventDetailPage extends StatefulWidget {
  final String eventId;

  const EventDetailPage({super.key, required this.eventId});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final EventService _eventService = EventService();

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

  //date/time parsing

  DateTime? _parseEventDateTime(String text) {
    final raw = text.trim();
    if (raw.isEmpty) return null;

    var normalized = raw.replaceAll(RegExp(r'\s+'), ' ');

    // normalize am/pm
    normalized = normalized.replaceAllMapped(
      RegExp(r'\b(am|pm)\b', caseSensitive: false),
          (m) => m.group(0)!.toUpperCase(),
    );

    // capitalise first letter of month name
    if (normalized.isNotEmpty) {
      normalized = normalized[0].toUpperCase() + normalized.substring(1);
    }

    final now = DateTime.now();

    final formats = <DateFormat>[
      DateFormat('MMM d, h:mm a'),
      DateFormat('MMM d, h a'),
      DateFormat('MM/dd/yyyy'),
      DateFormat('dd/MM/yyyy'),
      DateFormat('yyyy-MM-dd'),
    ];

    for (final f in formats) {
      try {
        final parsed = f.parseLoose(normalized);
        DateTime dt;

        if (f.pattern?.contains('MMM') == true) {

          dt = DateTime(
            now.year,
            parsed.month,
            parsed.day,
            parsed.hour,
            parsed.minute,
          );
        } else {
          // full date parsed
          final hour =
          (parsed.hour == 0 && parsed.minute == 0) ? 9 : parsed.hour;
          dt = DateTime(
            parsed.year,
            parsed.month,
            parsed.day,
            hour,
            parsed.minute,
          );
        }


        return dt;
      } catch (_) {
        // try next format
      }
    }

    return null;
  }

  //reminder scheduling

  Future<void> _scheduleReminder(BuildContext context) async {
    final event = _event;
    if (event == null) return;

    final dt = _parseEventDateTime(event.dateTimeText);
    if (dt == null) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('Cannot schedule reminder'),
          content: Text(
            'Could not understand the event date/time. '
                'Please edit the event and pick the time using the date/time picker.',
          ),
        ),
      );
      return;
    }

    final now = DateTime.now();

    // 1)  do NOT schedule past time
    if (dt.isBefore(now)) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('Cannot schedule reminder'),
          content: Text(
            'This event time is already in the past. '
                'You cannot set a reminder for a past time.',
          ),
        ),
      );
      return;
    }

    final diff = dt.difference(now);
    final bool moreThanTwoHours = diff > const Duration(hours: 2);

    await NotificationService.scheduleEventReminder(
      id: event.id,
      title: event.title,
      body:
      'Reminder: ${event.title} at ${event.locationName} on ${event.dateTimeText}',
      eventTime: dt,
    );

    if (!mounted) return;

    final message = moreThanTwoHours
        ? 'Reminder set: you will get a notification 2 hours before the event.'
        : 'Reminder set: the event is soon, you will get a notification shortly.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  //maps

  Future<void> _openInMaps(Event e) async {
    final query = Uri.encodeComponent(e.locationName);
    final uri =
    Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Maps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_event?.title ?? 'Event'),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF4C1D95),
                Color(0xFF6D28D9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF7F7FB),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _event == null
          ? const Center(child: Text('Event not found.'))
          : _buildContent(context, _event!, theme),
    );
  }

  Widget _buildContent(BuildContext context, Event e, ThemeData theme) {
    final hasImage = e.imageUrl != null && e.imageUrl!.trim().isNotEmpty;

    return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            if (hasImage) ...[
    ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: AspectRatio(
    aspectRatio: 16 / 9,
    child: Image.network(
    e.imageUrl!.trim(),
    fit: BoxFit.cover,
    loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return const Center(child: CircularProgressIndicator());
    },
    errorBuilder: (context, error, stackTrace) {
    return Container(
    color: Colors.grey[300],
    alignment: Alignment.center,
    child: const Icon(Icons.broken_image, size: 40),
    );
    },
    ),
    ),
    ),
    const SizedBox(height: 16),
    ],
    Card(
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(18),
    ),
    elevation: 3,
    child: Padding(
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    e.title,
    style: theme.textTheme.titleLarge?.copyWith(
    fontWeight: FontWeight.bold,
    color: Colors.black87,
    ),
    ),
    const SizedBox(height: 8),
    Text('Hosted by: ${e.hostName}'),
    const SizedBox(height: 4),
    Text('When: ${e.dateTimeText}'),
    const SizedBox(height: 4),
    Text('Where: ${e.locationName}'),
    const SizedBox(height: 12),
    Text(e.description),
    const SizedBox(height: 18),
    Row(
    children: [
    Expanded(
    child: OutlinedButton.icon(
    style: OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(
    vertical: 12,
    horizontal: 12,
    ),
    ),
    onPressed: () => _openInMaps(e),
    icon: const Icon(Icons.map_outlined),
    label: const Text('Open in Maps'),
    ),
    ),
    const SizedBox(width: 12),
    Expanded(
    child: ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(
    vertical: 12,
    horizontal: 12,
    ),
    ),
    onPressed: () => _scheduleReminder(context),
    icon: const Icon(
    Icons.notifications_active_outlined,
    ),
    label: const Text('Set reminder'),
    ),
    ),
    ],
    ),
    ],
    ),
    ),
    ),
    ],
    ),
    );
  }
}
