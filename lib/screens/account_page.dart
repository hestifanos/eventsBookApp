
import 'package:flutter/material.dart';
import '../models/app_user.dart';

class AccountPage extends StatelessWidget {
  final AppUser user;

  const AccountPage({
    super.key,
    required this.user,
  });

  // private function to return an user friendly label
  String _roleLabel(String role) {
    switch (role) {
      case 'organizer':
        return 'Event organizer';
      case 'student':
      default:
        return 'Student';
    }
  }

  @override
  Widget build(BuildContext context) {

    // take the current app theme and assign it to theme
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Top card with avatar & basic info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF4C1D95).withOpacity(0.15),
                    child: Text(
                      _initialForUser(user),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4C1D95),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? user.email,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _roleLabel(user.role),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF4C1D95),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Info section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'Name',
                    value: user.displayName ?? 'Not set',
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    label: 'Email',
                    value: user.email,
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    label: 'Role',
                    value: _roleLabel(user.role),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

          ],
        ),
      ),
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
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
