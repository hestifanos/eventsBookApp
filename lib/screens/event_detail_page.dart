import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/event_service.dart';
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

  Future<void> _openInMaps() async {
    final e = _event;
    if (e == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event not loaded yet')),
      );
      return;
    }

    Uri? uri;

    // 1) Prefer coordinates if they exist
    if (e.latitude != null && e.longitude != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${e.latitude},${e.longitude}',
      );
    }
    // 2) Otherwise, use the location name / address text
    else if (e.locationName.isNotEmpty) {
      final query = Uri.encodeComponent(e.locationName);
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$query',
      );
    }

    // 3) If we still have nothing, show an error
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
    return Scaffold(
      appBar: AppBar(title: Text(e.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hosted by: ${e.hostName}'),
              const SizedBox(height: 8),
              Text('When: ${e.dateTimeText}'),
              const SizedBox(height: 8),
              Text('Where: ${e.locationName}'),
              const SizedBox(height: 16),
              Text(e.description),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _openInMaps,
                child: const Text('Open in Google Maps'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
