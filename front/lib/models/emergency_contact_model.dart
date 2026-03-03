class EmergencyContactModel {
  final String name;
  final String phone;

  EmergencyContactModel({
    required this.name,
    required this.phone,
  });

  factory EmergencyContactModel.fromMap(Map<String, String> map) {
    return EmergencyContactModel(
      name: map['name']!,
      phone: map['phone']!,
    );
  }

  Map<String, String> toMap() {
    return {
      'name': name,
      'phone': phone,
    };
  }
}