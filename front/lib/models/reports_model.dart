class ReportModel {
  final String id;
  final String type;
  final double lat;
  final double lng;
  final DateTime expiresAt;

  ReportModel({
    required this.id,
    required this.type,
    required this.lat,
    required this.lng,
    required this.expiresAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'],
      type: json['type'],
      lat: json['lat'].toDouble(),
      lng: json['lng'].toDouble(),
      expiresAt: DateTime.parse(json['expires_at']).toUtc(),
    );
  }
}
