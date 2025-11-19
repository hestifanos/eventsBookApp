
import 'package:flutter/material.dart';
import '../services/event_service.dart';
import '../models/event.dart';
import '../widgets/event_card.dart';
import 'event_detail_page.dart';

class EventListPage extends StatelessWidget {
  const EventListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final eventService = EventService();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('Events'),
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
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<Event>>(
          stream: eventService.getEventsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final events = snapshot.data ?? [];

            if (events.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'No events yet. Check back soon or create one from the home screen.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 40,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final e in events)
                            EventCard(
                              event: e,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EventDetailPage(eventId: e.id),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
