import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emergency_event.dart';

class EmergencyHistoryService {
  EmergencyHistoryService._();

  static final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('emergency_events');

  static Future<void> logEvent({
    required String type,
    required String title,
    String? description,
    String? location,
    String status = 'Resolved',
  }) async {
    await _collection.add({
      'type': type,
      'title': title,
      'description': description,
      'location': location,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<EmergencyEvent>> eventsStream() {
    return _collection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final timestamp = data['timestamp'];
        DateTime ts;
        if (timestamp is Timestamp) {
          ts = timestamp.toDate();
        } else {
          ts = DateTime.tryParse(timestamp?.toString() ?? '') ?? DateTime.now();
        }

        return EmergencyEvent(
          id: doc.id,
          type: data['type'] as String? ?? 'unknown',
          title: data['title'] as String? ?? 'Emergency',
          description: data['description'] as String?,
          location: data['location'] as String?,
          status: data['status'] as String? ?? 'Resolved',
          timestamp: ts,
        );
      }).toList();
    });
  }
}

