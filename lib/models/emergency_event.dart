class EmergencyEvent {
  final String id;
  final String type; // e.g. sos, contact_call, hospital_call
  final String title;
  final String? description;
  final String? location;
  final String status; // e.g. Resolved, Cancelled, In Progress
  final DateTime timestamp;

  EmergencyEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.status,
    required this.timestamp,
    this.description,
    this.location,
  });

  factory EmergencyEvent.fromMap(String id, Map<String, dynamic> data) {
    return EmergencyEvent(
      id: id,
      type: data['type'] as String? ?? 'unknown',
      title: data['title'] as String? ?? 'Emergency',
      status: data['status'] as String? ?? 'Resolved',
      description: data['description'] as String?,
      location: data['location'] as String?,
      timestamp: (data['timestamp'] as DateTime?) ??
          DateTime.tryParse(data['timestamp']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'location': location,
      'status': status,
      'timestamp': timestamp,
    };
  }
}

