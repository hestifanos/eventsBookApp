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

  /// Upload an image to Firebase Storage and return its download URL.
  /// If [imageFile] is null OR upload fails with object-not-found, this returns null.
  Future<String?> _uploadEventImage(String eventId, XFile? imageFile) async {
    if (imageFile == null) return null;

    final file = File(imageFile.path);
    final ref = _storage.ref().child('event_images').child('$eventId.jpg');

    try {
      final snapshot = await ref.putFile(file);

      if (snapshot.state == TaskState.success) {
        // Only ask for URL AFTER a successful upload
        return await ref.getDownloadURL();
      } else {
        return null;
      }
    } on FirebaseException catch (e) {
      // If Storage says "object-not-found", just treat it as no image
      if (e.code == 'object-not-found') {
        // You could log this for debugging if you want:
        // debugPrint('Image object-not-found at ${ref.fullPath}');
        return null;
      }
      rethrow; // let other errors bubble up (permission, network, etc.)
    }
  }

  /// Upload a video to Firebase Storage and return its download URL.
  /// If [videoFile] is null OR upload fails with object-not-found, this returns null.
  Future<String?> _uploadEventVideo(String eventId, XFile? videoFile) async {
    if (videoFile == null) return null;

    final file = File(videoFile.path);
    final ref = _storage.ref().child('event_videos').child('$eventId.mp4');

    try {
      final snapshot = await ref.putFile(file);

      if (snapshot.state == TaskState.success) {
        return await ref.getDownloadURL();
      } else {
        return null;
      }
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        // debugPrint('Video object-not-found at ${ref.fullPath}');
        return null;
      }
      rethrow;
    }
  }

  /// Create a new event document. If [imageFile] or [videoFile] is provided,
  /// they are uploaded and their URLs stored on the Event.
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
    XFile? videoFile,
  }) async {
    final docRef = _eventsRef.doc(); // auto id
    final eventId = docRef.id;

    // Upload media first (if present)
    final imageUrl = await _uploadEventImage(eventId, imageFile);
    final videoUrl = await _uploadEventVideo(eventId, videoFile);

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
      videoUrl: videoUrl,
    );

    await docRef.set(event.toMap());
  }
}
