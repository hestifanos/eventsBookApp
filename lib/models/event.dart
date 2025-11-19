

class Event {
  final String id;
  final String title;
  final String description;
  final String hostId;
  final String hostName;
  final int maxAttendees;
  final int currentAttendees;
  final String dateTimeText;
  final String locationName;
  final double? latitude;
  final double? longitude;

  // Optional media fields
  final String? imageUrl;
  final String? videoUrl;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.hostId,
    required this.hostName,
    required this.maxAttendees,
    required this.currentAttendees,
    required this.dateTimeText,
    required this.locationName,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.videoUrl,
  });

  // from app to firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'hostId': hostId,
      'hostName': hostName,
      'maxAttendees': maxAttendees,
      'currentAttendees': currentAttendees,
      'dateTimeText': dateTimeText,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
    };
  }

  //from firestore to the app
  factory Event.fromMap(String id, Map<String, dynamic> map) {
    return Event(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      hostId: map['hostId'] as String? ?? '',
      hostName: map['hostName'] as String? ?? '',
      maxAttendees: (map['maxAttendees'] as num? ?? 0).toInt(),
      currentAttendees: (map['currentAttendees'] as num? ?? 0).toInt(),
      dateTimeText: map['dateTimeText'] as String? ?? '',
      locationName: map['locationName'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      imageUrl: map['imageUrl'] as String?,
      videoUrl: map['videoUrl'] as String?,
    );
  }
}
