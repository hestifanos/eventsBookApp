import 'package:campus_events/models/event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Event.fromMap', () {
    test('converts Firestore numeric values and preserves optional media', () {
      final event = Event.fromMap('event-1', {
        'title': 'Campus fair',
        'maxAttendees': 25.0,
        'currentAttendees': '4',
        'latitude': '43.6532',
        'longitude': -79.3832,
        'imageUrl': 'https://example.com/image.jpg',
      });

      expect(event.id, 'event-1');
      expect(event.title, 'Campus fair');
      expect(event.maxAttendees, 25);
      expect(event.currentAttendees, 4);
      expect(event.latitude, 43.6532);
      expect(event.longitude, -79.3832);
      expect(event.imageUrl, 'https://example.com/image.jpg');
      expect(event.videoUrl, isNull);
    });

    test('defaults missing optional fields', () {
      final event = Event.fromMap('event-2', {});

      expect(event.title, isEmpty);
      expect(event.maxAttendees, 0);
      expect(event.currentAttendees, 0);
      expect(event.latitude, isNull);
      expect(event.imageUrl, isNull);
    });

    test('rejects malformed stored fields instead of silently defaulting', () {
      for (final fields in [
        {'title': 42},
        {'maxAttendees': 'many'},
        {'currentAttendees': true},
        {'latitude': 'north'},
        {'imageUrl': 100},
      ]) {
        expect(
          () => Event.fromMap('event-3', fields),
          throwsA(isA<FormatException>()),
        );
      }
    });
  });
}
