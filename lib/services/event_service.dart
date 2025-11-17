// lib/services/event_service.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/event.dart';

class EventService {
  EventService();

  final CollectionReference<Map<String, dynamic>> _eventsRef =
  FirebaseFirestore.instance.collection('events');

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Stream all events in real time.
  Stream<List<Event>> getEventsStream() {
    return _eventsRef.snapshots().map(
          (snapshot) {
        return snapshot.docs
            .map(
              (doc) => Event.fromDoc(
            doc.id,
            doc.data(),
          ),
        )
            .toList();
      },
    );
  }

  /// Get a single event by id. Returns null if it doesn't exist.
  Future<Event?> getEvent(String id) async {
    final doc = await _eventsRef.doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    return Event.fromDoc(doc.id, data);
  }

  /// Delete an event by id.
  Future<void> deleteEvent(String id) async {
    await _eventsRef.doc(id).delete();
  }

  /// Internal helper: upload an image to Firebase Storage and return its URL.
  /// If [imageFile] is null, this returns null.
  Future<String?> _uploadEventImage(String eventId, XFile? imageFile) async {
    if (imageFile == null) return null;

    final file = File(imageFile.path);
    final ref = _storage.ref().child('event_images').child('$eventId.jpg');

    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  /// Create a new event document. If [imageFile] is provided,
  /// it is uploaded and its download URL stored in [Event.imageUrl].
  Future<void> createEvent({
    required String title,
    required String description,
    required String hostId,
    required String hostName,
    required int maxAttendees,
    required String dateTimeText,
    required String locationName,
    double? latitude,
    double? longitude,
    XFile? imageFile,
  }) async {
    final docRef = _eventsRef.doc(); // auto id
    final eventId = docRef.id;

    final imageUrl = await _uploadEventImage(eventId, imageFile);

    final event = Event(
      id: eventId,
      title: title,
      description: description,
      hostId: hostId,
      hostName: hostName,
      maxAttendees: maxAttendees,
      currentAttendees: 0,
      dateTimeText: dateTimeText,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      imageUrl: imageUrl,
    );

    await docRef.set(event.toMap());
  }
}
