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
    if (imageFile == null) {
      print('DEBUG: No image selected for event $eventId');
      return null;
    }

    final file = File(imageFile.path);
    final ref = _storage.ref().child('event_images/$eventId.jpg');

    try {
      print('DEBUG: Uploading image for event $eventId to ${ref.fullPath}');
      final snapshot = await ref.putFile(file);

      if (snapshot.state == TaskState.success) {
        final url = await ref.getDownloadURL();
        print('DEBUG: Image uploaded successfully. URL = $url');
        return url;
      } else {
        print('DEBUG: Image upload for $eventId did not reach success state.');
        return null;
      }
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        print('DEBUG: Image object-not-found at ${ref.fullPath}');
        return null;
      }
      print('ERROR: Image upload failed for $eventId → ${e.code}: ${e.message}');
      rethrow; // let other errors bubble up (permission, rules, network)
    } catch (e) {
      print('ERROR: Unexpected error during image upload for $eventId → $e');
      rethrow;
    }
  }

  /// Upload a video to Firebase Storage and return its download URL.
  /// If [videoFile] is null OR upload fails with object-not-found, this returns null.
  Future<String?> _uploadEventVideo(String eventId, XFile? videoFile) async {
    if (videoFile == null) {
      print('DEBUG: No video selected for event $eventId');
      return null;
    }

    final file = File(videoFile.path);
    final ref = _storage.ref().child('event_videos/$eventId.mp4');

    try {
      print('DEBUG: Uploading video for event $eventId to ${ref.fullPath}');
      final snapshot = await ref.putFile(file);

      if (snapshot.state == TaskState.success) {
        final url = await ref.getDownloadURL();
        print('DEBUG: Video uploaded successfully. URL = $url');
        return url;
      } else {
        print('DEBUG: Video upload for $eventId did not reach success state.');
        return null;
      }
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        print('DEBUG: Video object-not-found at ${ref.fullPath}');
        return null;
      }
      print('ERROR: Video upload failed for $eventId → ${e.code}: ${e.message}');
      rethrow;
    } catch (e) {
      print('ERROR: Unexpected error during video upload for $eventId → $e');
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

    print('DEBUG: Creating event $eventId with title "$title"');

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
    print('DEBUG: Event $eventId saved to Firestore with imageUrl=$imageUrl videoUrl=$videoUrl');
  }
}
