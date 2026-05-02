class EmergencyContact {
  final String name;
  final String phoneNumber;
  final String? email;
  final String? relationship;

  const EmergencyContact({
    required this.name,
    required this.phoneNumber,
    this.email,
    this.relationship,
  });
}

