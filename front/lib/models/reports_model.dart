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
      // On utilise des clés qui correspondent exactement au JSON de ton API Python
      id: json['id'].toString(),
      type: json['type'] as String,
      // .toDouble() est vital ici au cas où le serveur envoie un entier
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      // Parsing de la date avec conversion UTC
      expiresAt: DateTime.parse(json['expires_at']).toUtc(),
    );
  }
}
