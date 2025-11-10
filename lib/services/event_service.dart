import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

class EventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _events => _db.collection('events');

  Future<void> createEvent(Event event) async {
    final doc = _events.doc();
    await doc.set(event.toMap());
  }

  Stream<List<Event>> getEventsStream() {
    return _events.orderBy('dateTimeText').snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => Event.fromDoc(
          doc.id,
          doc.data() as Map<String, dynamic>,
        ),
      )
          .toList();
    });
  }

  Future<Event?> getEvent(String id) async {
    final doc = await _events.doc(id).get();
    if (!doc.exists) return null;
    return Event.fromDoc(doc.id, doc.data() as Map<String, dynamic>);
  }

  /// Admin: delete an event by id
  Future<void> deleteEvent(String id) async {
    await _events.doc(id).delete();
  }
}
