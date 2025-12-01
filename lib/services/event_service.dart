
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

  // Stream all events in real time.
  Stream<List<Event>> getEventsStream() {
    return _eventsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => Event.fromMap(
          doc.id,
          doc.data(),
        ),
      )
          .toList();
    });
  }

  // get a single event by id
  Future<Event?> getEvent(String id) async {
    final doc = await _eventsRef.doc(id).get();
    if (!doc.exists) return null;
    return Event.fromMap(doc.id, doc.data()!);
  }

  // Create a new event document and optionally upload image or video.
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
    // create the firestore document without media URLs.
    final docRef = await _eventsRef.add({
      'title': title,
      'description': description,
      'hostId': hostId,
      'hostName': hostName,
      'maxAttendees': maxAttendees,
      'currentAttendees': 0,
      'dateTimeText': dateTimeText,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': null,
      'videoUrl': null,
    });

    final eventId = docRef.id;

    String? imageUrl;
    String? videoUrl;

    // Upload media if provided.
    imageUrl = await _uploadEventImage(eventId, imageFile);
    videoUrl = await _uploadEventVideo(eventId, videoFile);

    // update firestore if we got any URLs.
    if (imageUrl != null || videoUrl != null) {
      await docRef.update({
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (videoUrl != null) 'videoUrl': videoUrl,
      });
    }
  }

  // delete an event and its media as well.
  Future<void> deleteEvent(String id) async {
    await _eventsRef.doc(id).delete();

    try {
      final folderRef = _storage.ref().child('events').child(id);
      final listResult = await folderRef.listAll();
      for (final item in listResult.items) {
        await item.delete();
      }
    } catch (_) {

    }
  }

  Future<String?> _uploadEventImage(String eventId, XFile? imageFile) async {
    if (imageFile == null) {
      print('No image selected for event $eventId');
      return null;
    }

    final file = File(imageFile.path);
    if (!file.existsSync()) {
      print('Local image file does not exist: ${imageFile.path}');
      return null;
    }

    final fileName = imageFile.name.isNotEmpty
        ? imageFile.name
        : 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final ext = fileName.split('.').last.toLowerCase();
    final contentType =
    ext == 'png' ? 'image/png' : ext == 'webp' ? 'image/webp' : 'image/jpeg';

    final ref = _storage
        .ref()
        .child('events')
        .child(eventId)
        .child('images')
        .child(fileName);

    try {
      final snapshot =
      await ref.putFile(file, SettableMetadata(contentType: contentType));

      if (snapshot.state != TaskState.success) {
        print(
            'Image upload incomplete for event $eventId (state: ${snapshot.state})');
        return null;
      }

      final url = await snapshot.ref.getDownloadURL();
      print('Image uploaded successfully for $eventId: $url');
      return url;
    } on FirebaseException catch (e) {
      print(
          'Image upload failed for event $eventId: ${e.code} ${e.message}');
      return null;
    }
  }

  Future<String?> _uploadEventVideo(String eventId, XFile? videoFile) async {
    if (videoFile == null) {
      print('No video selected for event $eventId');
      return null;
    }

    final file = File(videoFile.path);
    if (!file.existsSync()) {
      print('Local video file does not exist: ${videoFile.path}');
      return null;
    }

    final fileName = videoFile.name.isNotEmpty
        ? videoFile.name
        : 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final ref = _storage
        .ref()
        .child('events')
        .child(eventId)
        .child('videos')
        .child(fileName);

    try {
      final snapshot = await ref.putFile(
        file,
        SettableMetadata(contentType: 'video/mp4'),
      );

      if (snapshot.state != TaskState.success) {
        print(
            'Video upload incomplete for event $eventId (state: ${snapshot.state})');
        return null;
      }

      final url = await snapshot.ref.getDownloadURL();
      print('Video uploaded successfully for $eventId: $url');
      return url;
    } on FirebaseException catch (e) {
      print(
          'Video upload failed for event $eventId: ${e.code} ${e.message}');
      return null;
    }
  }
}
