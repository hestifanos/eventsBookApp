

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
      title: _readString(map['title']),
      description: _readString(map['description']),
      hostId: _readString(map['hostId']),
      hostName: _readString(map['hostName']),
      maxAttendees: _readInt('maxAttendees', map['maxAttendees']),
      currentAttendees: _readInt('currentAttendees', map['currentAttendees']),
      dateTimeText: _readString(map['dateTimeText']),
      locationName: _readString(map['locationName']),
      latitude: _readDouble('latitude', map['latitude']),
      longitude: _readDouble('longitude', map['longitude']),
      imageUrl: _readOptionalString('imageUrl', map['imageUrl']),
      videoUrl: _readOptionalString('videoUrl', map['videoUrl']),
    );
  }

  static String _readString(Object? value) {
    if (value == null) return '';
    if (value is String) return value;
    throw FormatException('Expected a string value');
  }

  static String? _readOptionalString(String field, Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    throw FormatException('$field must be a string');
  }

  static int _readInt(String field, Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.toInt()) {
      return value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('$field must be an integer');
  }

  static double? _readDouble(String field, Object? value) {
    if (value == null) return null;
    if (value is num && value.isFinite) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null && parsed.isFinite) return parsed;
    }
    throw FormatException('$field must be a finite number');
  }
}
