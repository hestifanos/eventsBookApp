import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../models/app_user.dart';
import '../models/event.dart';
import '../widgets/event_card.dart';
import 'create_event_page.dart';
import 'event_list_page.dart';
import 'account_page.dart';
import 'admin_page.dart';
import 'map_page.dart';
import 'login_page.dart';
import 'event_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _authService = AuthService();
  final _eventService = EventService();
  AppUser? _appUser;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentAppUser();
    if (!mounted) return;
    setState(() {
      _appUser = user;
      _loadingUser = false;
    });
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage()),
          (_) => false,
    );
  }

  String _initialForUser(AppUser user) {
    final source = (user.displayName != null &&
        user.displayName!.trim().isNotEmpty)
        ? user.displayName!.trim()
        : user.email.trim();
    if (source.isEmpty) return '?';
    return source[0].toUpperCase();
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style:
                theme.textTheme.labelLarge?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUser || _appUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = _appUser!;
    final isOrganizer = user.role == 'organizer';
    final theme = Theme.of(context);

    //header
    final header = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF4C1D95),
            Color(0xFF6D28D9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // top row: title + icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Campus Events',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Account',
                    icon: const Icon(
                      Icons.person_outline,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AccountPage(user: user),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Log out',
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.white,
                    ),
                    onPressed: _logout,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withOpacity(0.15),
                child: Text(
                  _initialForUser(user),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white70),
                  ),
                  Text(
                    user.displayName ?? user.email,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isOrganizer ? 'Event organizer' : 'Student',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // quick actions row (same for both)
          Row(
            children: [
              _quickActionButton(
                icon: Icons.explore_outlined,
                label: 'Browse events',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => EventListPage()),
                  );
                },
              ),
              const SizedBox(width: 12),
              _quickActionButton(
                icon: Icons.map_outlined,
                label: 'Campus map',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => MapPage()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      body: SafeArea(
        child: Column(
          children: [
            header,
            Expanded(
              child: isOrganizer
                  ? _OrganizerBody(user: user)
                  : _StudentEventsBody(eventService: _eventService),
            ),
          ],
        ),
      ),
    );
  }
}

// student home

class _StudentEventsBody extends StatelessWidget {
  final EventService eventService;

  const _StudentEventsBody({required this.eventService});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding:
          const EdgeInsets.symmetric(horizontal: 0.0, vertical: 16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: Text(
                    'Events',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                StreamBuilder<List<Event>>(
                  stream: eventService.getEventsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final events = snapshot.data ?? [];
                    if (events.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 24),
                        child: Text(
                          'No events yet. Check back soon!',
                        ),
                      );
                    }

                    return Column(
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
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// organizer home

class _OrganizerBody extends StatelessWidget {
  final AppUser user;

  const _OrganizerBody({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What would you like to do?',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _HomeActionCard(
                icon: Icons.event_available_outlined,
                title: 'Browse Events',
                description: 'Discover what’s happening on campus today.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => EventListPage()),
                  );
                },
              ),
              _HomeActionCard(
                icon: Icons.add_circle_outline,
                title: 'Create Event',
                description:
                'Host a new event and reach more students.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CreateEventPage()),
                  );
                },
              ),
              _HomeActionCard(
                icon: Icons.dashboard_customize_outlined,
                title: 'Admin',
                description:
                'Manage your events, stats and visibility.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminPage(user: user),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: title,
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 2 - 22,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
